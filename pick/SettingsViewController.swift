//
//  SettingsViewController.swift
//  pick
//
//  Created by kylefang on 9/15/15.
//  Copyright © 2015 hackplan. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SettingsViewController: UITableViewController {

    @IBOutlet weak var dataSource: UITextView!
    @IBOutlet weak var hint: UITextField!

    @IBOutlet weak var skipWinners: UISwitch!
    @IBOutlet weak var restartAutomatically: UISwitch!

    @IBOutlet weak var animationSpeed: UISegmentedControl!
    @IBOutlet weak var animationDuration: UISegmentedControl!

    @IBOutlet weak var resetSelecteds: UITableViewCell!

    let disappear:PublishSubject<()> = PublishSubject()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }

    let disposeBag = DisposeBag()

    func setup() {
        self.skipWinners.on = DataHolder.shared.skipWinners
        self.restartAutomatically.on = DataHolder.shared.autoRestart

        let skipWinnerSignal = self.skipWinners.rx_value.doOn(next: { s in
            DataHolder.shared.skipWinners = s
        }).publish()
        skipWinnerSignal.bindTo(self.restartAutomatically.rx_enabled)
            .addDisposableTo(disposeBag)
        skipWinnerSignal.subscribeNext({[unowned self] s in
            self.resetSelecteds.textLabel?.enabled = s
            self.resetSelecteds.userInteractionEnabled = s
        }).addDisposableTo(disposeBag)
        skipWinnerSignal.connect()
            .addDisposableTo(disposeBag)

        self.restartAutomatically.rx_value.subscribeNext({ r in
            DataHolder.shared.autoRestart = r
        }).addDisposableTo(disposeBag)

        let resetWinnersIndex = NSIndexPath(forRow: 0, inSection: 2)
        let resetSignal:Observable<NSIndexPath> = self.tableView.rx_itemSelected.filter({$0 == resetWinnersIndex})
            .doOn(next:{[unowned self] i in
            self.tableView.deselectRowAtIndexPath(i, animated: true)
        })
        resetSignal.flatMap({ _ -> Observable<Int> in
            let winners = DataHolder.shared.selectedCandidates.joinWithSeparator(",")
            let al = UIAlertView(title: "Reset Selecteds", message: "Do you want to reset \(winners), and start again?", delegate: nil, cancelButtonTitle: "Cancel", otherButtonTitles: "Delete")
            al.show()
            return al.rx_clickedButtonAtIndex.filter({$0 != al.cancelButtonIndex })
        }).subscribeNext({ _ in
            DataHolder.shared.selectedCandidates = []
        }).addDisposableTo(disposeBag)

        self.hint.text = DataHolder.shared.hint
        [self.hint.rx_text.throttle(1, MainScheduler.sharedInstance), self.disappear.map({[unowned self] _ -> String in return self.hint.text ?? "Hit it"})].asObservable().merge()
        .subscribeNext({ DataHolder.shared.hint = $0 })
        self.dataSource.text = DataHolder.shared.candidates.joinWithSeparator("\n")
        self.dataSource.rx_text.throttle(1, MainScheduler.sharedInstance).map({ (t:String) in
            return t.componentsSeparatedByString("\n")
        }).subscribeNext({ data in
            DataHolder.shared.candidates = data
        }).addDisposableTo(disposeBag)

        animationSpeed.selectedSegmentIndex = DataHolder.shared.animationSpeed.rawValue
        animationSpeed.rx_value
            .subscribeNext({DataHolder.shared.animationSpeed = DataHolder.AnimationSpeed(rawValue: $0)!})
            .addDisposableTo(disposeBag)

        animationDuration.selectedSegmentIndex = Int(DataHolder.shared.animaitonDuration)
        animationDuration.rx_value
            .subscribeNext({ DataHolder.shared.animaitonDuration = Double($0) })
            .addDisposableTo(disposeBag)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        disappear.on(Event.Next(()))
    }
}