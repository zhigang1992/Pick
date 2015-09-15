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

    var animating = false

    var startSignal:Observable<()> {
        return tap.rx_event.filter({[unowned self] _ in return !self.animating}).map({ _ in return () })
            .doOn(next: {[unowned self] _ in self.animating = true})
    }

    var stopSignal:Observable<()> {
        let manualSignal:Observable<()> = tap.rx_event.filter({[unowned self] _ in return self.animating}).map({ _ in return () })
        return [manualSignal, self.disappear].asObservable().merge()
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

        return  [pinchSignal, rotateSignal].asObservable().merge()
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
        self.startSignal
            .flatMap({[unowned self] _ -> Observable<Int64> in
                return interval(0.03, MainScheduler.sharedInstance).takeUntil(self.stopSignal)
                })
            .map({ _ -> (UIColor, String) in
                let color = UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0)
                let text = "\(rand()%100)"
                return (color, text)
            })
            .subscribeNext({[unowned self] color, text in
                self.text.text = text
                self.view.backgroundColor = color
                })
            .addDisposableTo(disposeBag)

        self.fontSizeSignal
            .map({ UIFont.systemFontOfSize($0) })
            .subscribeNext({ [unowned self] font in
                self.text.font = font
                })
            .addDisposableTo(disposeBag)

        self.holdSignal
            .subscribeNext({ [unowned self] _ in
                self.performSegueWithIdentifier(Segue.Settings.identifier!, sender: nil)
                })
            .addDisposableTo(disposeBag)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }

    @IBAction func doneSetting(segue:UIStoryboardSegue) {
        setup()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        disappear.on(Event.Next(()))
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        screenRotate.on(Event.Next(()))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
}

