//
//  PresetViewController.swift
//  pick
//
//  Created by kylefang on 9/16/15.
//  Copyright © 2015 hackplan. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyJSON
import APAddressBook

struct Preset {
    let name:String
    let hint:String
    let candidate:[String]
    let skipWinner:Bool
    let autoRestart:Bool
    var prerender:Observable<Preset>?
    func saveToUserDefault() {
        let dataHolder = DataHolder.shared
        dataHolder.hint = self.hint
        dataHolder.candidates = self.candidate
        dataHolder.skipWinners = self.skipWinner
        dataHolder.autoRestart = self.autoRestart
    }
    init (name:String, hint:String, candidate:[String], skipWinner:Bool, autoRestart:Bool) {
        self.name = name
        self.hint = hint
        self.candidate = candidate
        self.skipWinner = skipWinner
        self.autoRestart = autoRestart
    }
}

class PresetViewController: UITableViewController {
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, Preset>>()
    typealias Section = SectionModel<String, Preset>

    let disposeBag = DisposeBag()

    static let presets:[Preset] = {
        let path = NSBundle.mainBundle().pathForResource("presets", ofType: "json")!

        let content = try! NSJSONSerialization.JSONObjectWithData(NSData(contentsOfFile: path)!, options: NSJSONReadingOptions.MutableContainers)
        let json = JSON(content)
        return json.arrayValue.map({ (json:JSON) in
            return Preset(name:json["name"].stringValue,
                hint: json["hint"].stringValue,
                candidate: json["candidate"].arrayValue.map({$0.stringValue}),
                skipWinner: json["skipWinner"].boolValue,
                autoRestart: json["autoRestart"].boolValue)
        })
        }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = nil
        self.tableView.dataSource = nil

        var contactPreset = Preset(name: "Contacts", hint: "Choose", candidate: [], skipWinner: true, autoRestart: true)

        contactPreset.prerender = create({ subscribe -> Disposable in
            APAddressBook().loadContacts({ (contacts, error) -> Void in
                if contacts == nil {
                    subscribe.on(Event.Error(NSError(domain: "System", code: 403, userInfo: [NSLocalizedDescriptionKey: "Please allow access in Settings.app"])))
                } else {
                    let candidates = contacts.map({ (contact) -> String in
                        let names:String = [contact.firstName, contact.middleName, contact.lastName].flatMap{ name in
                            return name.map({$0})
                        }.joinWithSeparator(" ")
                        return names
                    })
                    subscribe.on(Event.Next(Preset(name: contactPreset.name, hint: contactPreset.hint, candidate: candidates, skipWinner: contactPreset.skipWinner, autoRestart: contactPreset.autoRestart)))
                }
            })
            return AnonymousDisposable {

            }
        })

        let allPresets = just([
            SectionModel(model: "", items: [Preset(name: "Tutorial", hint: "Hit it", candidate: ["Shake", "Pinch", "Hold"], skipWinner: true, autoRestart: true)]),
            SectionModel(model: "", items: PresetViewController.presets),
            SectionModel(model: "", items: [contactPreset]),
            ])

        dataSource.cellFactory = { (tv, ip, preset:Preset) in
            let cell = tv.dequeueReusableCellWithIdentifier(Reusable.Preset.identifier!, forIndexPath: ip)
            cell.textLabel?.text = preset.name
            return cell
        }

        allPresets.bindTo(self.tableView.rx_itemsWithDataSource(self.dataSource)).addDisposableTo(disposeBag)

        self.tableView
            .rx_itemSelected
            .doOn(next:{[unowned self] ip in self.tableView.deselectRowAtIndexPath(ip, animated: true)})
            .map({[unowned self] ip in return self.dataSource.itemAtIndexPath(ip) })
            .flatMap({ (preset:Preset) -> Observable<Preset> in
                return preset.prerender?.doOn(error:{ (error:ErrorType) in
                    UIAlertView(title: "Error", message: (error as NSError).localizedDescription, delegate: nil, cancelButtonTitle: "Okay").show()
                }).catchErrorJustReturn(preset) ?? just(preset)
            })
            .filter({$0.candidate.count > 0})
            .subscribeNext({[unowned self] (preset:Preset) in
                preset.saveToUserDefault()
                self.performSegue(Segue.done)
        }).addDisposableTo(disposeBag)
    }

}
