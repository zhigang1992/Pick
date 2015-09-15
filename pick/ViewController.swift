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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        var animating = false

        let stopSignal = [tap.rx_event
            .filter({_ in animating})
            .map({_ in ()}), disappear]
            .asObservable()
            .merge()
            .doOn(next: {_ in animating = false})

        tap.rx_event
            .filter({_ in !animating})
            .doOn(next: {_ in animating = true})
            .flatMap({ _ in
                interval(0.03, MainScheduler.sharedInstance)
                    .takeUntil(stopSignal)
            })
            .map({ _ -> UIColor in
                let randomRed = CGFloat(drand48())
                let randomGreen = CGFloat(drand48())
                let randomBlue = CGFloat(drand48())
                return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
            })
            .subscribeNext({ [unowned self] color in
                self.view.backgroundColor = color
            })
            .addDisposableTo(disposeBag)


        [pinch.rx_event
            .map({ ($0 as! UIPinchGestureRecognizer).scale })
            .scan((1.0, 1.0)){ ($0.1, $1) }
            .map({ $1 / $0 })
            .filter({ [unowned self] _ in
                return self.pinch.state == .Changed
                }),
            self.screenRotate
                .map({[unowned self] in
                    let size = self.view.bounds.size
                    return size.height / size.width
                })].asObservable().merge()
            .map({ [unowned self] scale in
                return self.text.font.pointSize * scale
            })
            .map({ fontSize -> CGFloat in
                let size = UIScreen.mainScreen().bounds.size
                let fontMaxSize = min(size.width, size.height) * 0.6
                return max(min(fontSize, fontMaxSize), 40)
            })
            .map({ UIFont.systemFontOfSize($0) })
            .subscribeNext({ [unowned self] font in
                self.text.font = font
            })
            .addDisposableTo(disposeBag)

        hold.rx_event
            .filter({$0.state == .Began})
            .subscribeNext({ [unowned self] _ in
                self.performSegueWithIdentifier("Settings", sender: nil)
            })
            .addDisposableTo(disposeBag)
    }

    @IBAction func doneSetting(segue:UIStoryboardSegue) {

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

