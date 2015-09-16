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

struct Preset {
    let name:String
    let hint:String
    let candidate:[String]
    let skipWinner:Bool
    let autoRestart:Bool
    func saveToUserDefault() {
        let dataHolder = DataHolder.shared
        dataHolder.hint = self.hint
        dataHolder.candidates = self.candidate
        dataHolder.skipWinners = self.skipWinner
        dataHolder.autoRestart = self.autoRestart
    }
}

class PresetViewController: UITableViewController {
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, Preset>>()
    typealias Section = SectionModel<String, Preset>

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = nil
        self.tableView.dataSource = nil

        let path = NSBundle.mainBundle().pathForResource("presets", ofType: "json")!

        let content = try! NSJSONSerialization.JSONObjectWithData(NSData(contentsOfFile: path)!, options: NSJSONReadingOptions.MutableContainers)
        let json = JSON(content)
        let presets = json.arrayValue.map({ (json:JSON) in
            return Preset(name:json["name"].stringValue,
                hint: json["hint"].stringValue,
                candidate: json["candidate"].arrayValue.map({$0.stringValue}),
                skipWinner: json["skipWinner"].boolValue,
                autoRestart: json["autoRestart"].boolValue)
        })

        let allPresets = just([SectionModel(model: "", items: presets)])

        dataSource.cellFactory = { (tv, ip, preset:Preset) in
            let cell = tv.dequeueReusableCellWithIdentifier(Reusable.Preset.identifier!, forIndexPath: ip)
            cell.textLabel?.text = preset.name
            return cell
        }

        allPresets.bindTo(self.tableView.rx_itemsWithDataSource(self.dataSource)).addDisposableTo(disposeBag)

        self.tableView
            .rx_itemSelected
            .map({[unowned self] ip in return self.dataSource.itemAtIndexPath(ip) })
            .subscribeNext({[unowned self] (preset:Preset) in
                preset.saveToUserDefault()
                self.performSegue(Segue.done)
        }).addDisposableTo(disposeBag)
    }

}
