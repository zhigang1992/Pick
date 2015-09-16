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
import MessageUI

class SettingsViewController: UITableViewController, MFMailComposeViewControllerDelegate {

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

        let tableSelect = self.tableView.rx_itemSelected.doOn(next:{[unowned self] i in
            self.tableView.deselectRowAtIndexPath(i, animated: true)
            }).publish()
        tableSelect.connect().addDisposableTo(disposeBag)

        let resetSignal:Observable<NSIndexPath> = tableSelect
            .filter({$0 == resetWinnersIndex})
        resetSignal.flatMap({ _ -> Observable<Int> in
            let winners = DataHolder.shared.selectedCandidates.joinWithSeparator(",")
            let al = UIAlertView(title: "Reset Selecteds", message: "Do you want to reset \(winners), and start again?", delegate: nil, cancelButtonTitle: "Cancel", otherButtonTitles: "Delete")
            al.show()
            return al.rx_clickedButtonAtIndex.filter({$0 != al.cancelButtonIndex })
        }).subscribeNext({ _ in
            DataHolder.shared.selectedCandidates = []
        }).addDisposableTo(disposeBag)

        let feedbackIndexPath = NSIndexPath(forRow: 0, inSection: 5)
        let feedbackSignal:Observable<NSIndexPath> = tableSelect.filter({$0 == feedbackIndexPath})
        feedbackSignal.subscribeNext({[unowned self] _ in
            let mailVC = MFMailComposeViewController()
            mailVC.mailComposeDelegate = self
            mailVC.setSubject("[Pick] Feedback")
            mailVC.setToRecipients(["zhigang1992+pick@gmail.com"])
            self.presentViewController(mailVC, animated: true, completion: nil)
        }).addDisposableTo(disposeBag)

        self.hint.text = DataHolder.shared.hint
        [self.hint.rx_text.throttle(1, MainScheduler.sharedInstance), self.disappear.map({[unowned self] _ -> String in     return self.hint.text ?? "Hit it"})].asObservable().merge()
            .subscribeNext({ DataHolder.shared.hint = $0 })
            .addDisposableTo(disposeBag)

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

    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        disappear.on(Event.Next(()))
    }
}