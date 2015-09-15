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

    @IBOutlet weak var skipWinners: UISwitch!
    @IBOutlet weak var restartAutomatically: UISwitch!

    @IBOutlet weak var animationSpeed: UISegmentedControl!
    @IBOutlet weak var animationDuration: UISegmentedControl!

    @IBOutlet weak var resetSelecteds: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }

    let disposeBag = DisposeBag()

    func setup() {
        let skipWinnerSignal = self.skipWinners.rx_value.publish()

        skipWinnerSignal.bindTo(self.restartAutomatically.rx_enabled).addDisposableTo(disposeBag)
        skipWinnerSignal.subscribeNext({[unowned self] s in
            self.resetSelecteds.textLabel?.enabled = s
        }).addDisposableTo(disposeBag)
        skipWinnerSignal.subscribeNext({s in
            DataHolder.shared.skipWinners = s
        })
        skipWinnerSignal.connect().addDisposableTo(disposeBag)

        self.restartAutomatically.rx_value.subscribeNext({ r in
            DataHolder.shared.autoRestart = r
        }).addDisposableTo(disposeBag)

        let resetWinnersIndex = NSIndexPath(forRow: 0, inSection: 2)
        let resetSignal:Observable<NSIndexPath> = self.tableView.rx_itemSelected.filter({$0 == resetWinnersIndex})
            .doOn(next:{[unowned self] i in
            self.tableView.deselectRowAtIndexPath(i, animated: true)
        })
        resetSignal.flatMap({ _ -> Observable<Int> in
            let al = UIAlertView(title: "Reset Selecteds", message: "Do you want to reset winners, and start again?", delegate: nil, cancelButtonTitle: "Cancel", otherButtonTitles: "Delete")
            al.show()
            return al.rx_clickedButtonAtIndex.filter({$0 != al.cancelButtonIndex })
        }).subscribeNext({ _ in
            DataHolder.shared.selectedCandidates = []
        }).addDisposableTo(disposeBag)

        self.dataSource.text = DataHolder.shared.candidates.joinWithSeparator("\n")
        self.skipWinners.on = DataHolder.shared.skipWinners
        self.restartAutomatically.on = DataHolder.shared.autoRestart
    }
}