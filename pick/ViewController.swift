//
//  ViewController.swift
//  pick
//
//  Created by kylefang on 9/12/15.
//  Copyright © 2015 hackplan. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {

    @IBOutlet var pinch: UIPinchGestureRecognizer!
    @IBOutlet var tap: UITapGestureRecognizer!
    @IBOutlet var hold: UILongPressGestureRecognizer!
    @IBOutlet weak var text: UILabel!

    let disposeBag = DisposeBag()

    let disappear:PublishSubject<()> = PublishSubject()

    let screenRotate:PublishSubject<()> = PublishSubject()

    let shake:PublishSubject<()> = PublishSubject()

    var animating = false

    var startSignal:Observable<()> {
        let tapStart = tap.rx_event.map({ _ in return () })

        return sequenceOf(tapStart, shake).merge()
            .filter({[unowned self] _ in return !self.animating})
            .doOn(next: {
                if DataHolder.shared.autoRestart && DataHolder.shared.availableCadidates.count == 0 {
                    DataHolder.shared.selectedCandidates = []
                }
            })
            .filter({[unowned self] _ in
                let valid = DataHolder.shared.availableCadidates.count > 0
                if !valid {
                    let av = UIAlertView(title: "Finished", message: "All candidate has been selected", delegate: nil, cancelButtonTitle: "Okay", otherButtonTitles: "Restart")
                    av.show()
                    av.rx_clickedButtonAtIndex.filter({$0 != av.cancelButtonIndex}).subscribeNext({ _ in
                        DataHolder.shared.selectedCandidates = []
                    }).addDisposableTo(self.disposeBag)
                }
                return valid
            })
            .doOn(next: {[unowned self] _ in self.animating = true})
    }

    var stopSignal:Observable<()> {
        let animationDuration = DataHolder.shared.animaitonDuration
        let autoStopSignal:Observable<()> = animationDuration > 0 ? interval(animationDuration, MainScheduler.sharedInstance).take(1).map({_ in return () }) : empty()
        let manualSignal:Observable<()> = [tap.rx_event.map({_ in return () }), autoStopSignal, shake]
            .asObservable()
            .merge()
            .take(1)
            .filter({[unowned self] _ in return self.animating})
            .map({ _ in return () })
            .doOn(next:{[unowned self] _ in
                let winner = DataHolder.shared.availableCadidates.sample()!
                DataHolder.shared.addSelect(winner)
                self.text.text = winner
            })
        return sequenceOf(manualSignal, self.disappear).merge()
                    .doOn(next: {[unowned self] _ in self.animating = false})
    }

    var fontSizeSignal:Observable<CGFloat> {
        let pinchSignal:Observable<CGFloat> = self.pinch.rx_event
            .map({ ($0 as! UIPinchGestureRecognizer).scale })
            .scan((1.0, 1.0)){ ($0.1, $1) }
            .map({ $1 / $0 })
            .filter({ [unowned self] _ in
                return self.pinch.state == .Changed
                })

        let rotateSignal:Observable<CGFloat> = self.screenRotate
            .map({[unowned self] in
                let size = self.view.bounds.size
                return size.height / size.width
                })

        return  sequenceOf(pinchSignal, rotateSignal).merge()
            .map({ [unowned self] scale in
                return self.text.font.pointSize * scale
                })
            .map({ fontSize -> CGFloat in
                let size = UIScreen.mainScreen().bounds.size
                let fontMaxSize = min(size.width, size.height) * 0.6
                return max(min(fontSize, fontMaxSize), 40)
            })
    }

    var holdSignal:Observable<()> {
        return self.hold.rx_event.filter({$0.state == .Began}).map({_ in return () })
    }

    func setup() {

        setupDefault()

        self.startSignal
            .flatMap({[unowned self] _ -> Observable<Int64> in
                let time = DataHolder.shared.animationSpeed.speed
                return interval(time, MainScheduler.sharedInstance).takeUntil(self.stopSignal)
                })
            .map({ _ -> (UIColor, String) in
                let color = UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0)
                let text = DataHolder.shared.candidates.sample()!
                return (color, text)
            })
            .subscribeNext({[unowned self] color, text in
                self.text.text = text
                self.view.backgroundColor = color
                })
            .addDisposableTo(disposeBag)

        let fontChanged = self.fontSizeSignal.publish()
        fontChanged.throttle(0.5, MainScheduler.sharedInstance)
            .subscribeNext({ (fontSize:CGFloat) in
                    DataHolder.shared.fontSize = Float(fontSize)
            }).addDisposableTo(disposeBag)

        fontChanged.map({ UIFont.systemFontOfSize($0) })
            .subscribeNext({ [unowned self] font in
                self.text.font = font
                })
            .addDisposableTo(disposeBag)

        fontChanged.connect().addDisposableTo(disposeBag)

        self.holdSignal
            .subscribeNext({ [unowned self] _ in
                self.performSegueWithIdentifier(Segue.Settings.identifier!, sender: nil)
                })
            .addDisposableTo(disposeBag)
    }

    func setupDefault() {
        self.text.font = UIFont.systemFontOfSize(CGFloat(DataHolder.shared.fontSize))
        self.text.text = DataHolder.shared.hint
        self.view.backgroundColor = UIColor.whiteColor()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }

    @IBAction func doneSetting(segue:UIStoryboardSegue) {
        setupDefault()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        disappear.on(.Next(()))
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        screenRotate.on(.Next(()))
    }

    override func canBecomeFirstResponder() -> Bool {
        return true
    }

    override func motionBegan(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if motion == .MotionShake {
            shake.on(.Next(()))
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
}

