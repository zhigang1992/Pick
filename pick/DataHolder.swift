//
//  DataHolder.swift
//  pick
//
//  Created by kylefang on 9/15/15.
//  Copyright © 2015 hackplan. All rights reserved.
//

import Foundation

let hint_key = "hint"
let candidates_key = "candidates"
let selected_candidates_key = "winners"
let skip_winner_key = "skipCandidate"
let auto_restart_key = "autoRestart"

let animation_speed_key = "anmiationSpeed"
let animation_duration_key = "anmiationDuration"

let font_size_key = "fontSize"

class DataHolder {
    static let shared = DataHolder()

    let defaults = NSUserDefaults.standardUserDefaults()

    var hint:String {
        didSet {
            defaults.setObject(hint, forKey: hint_key)
        }
    }

    var candidates:[String] {
        didSet {
            defaults.setObject(candidates, forKey: candidates_key)
            selectedCandidates = []
        }
    }

    var selectedCandidates:[String] {
        didSet {
            defaults.setObject(selectedCandidates, forKey: selected_candidates_key)
        }
    }

    func addSelect(candidate:String) {
        self.selectedCandidates.append(candidate)
    }

    var availableCadidates:[String] {
        if self.skipWinners {
            let avaiableSet = Set(self.candidates).subtract(Set(self.selectedCandidates))
            return Array(avaiableSet)
        }
        return self.candidates
    }

    var skipWinners:Bool {
        didSet {
            defaults.setBool(skipWinners, forKey: skip_winner_key)
        }
    }

    var autoRestart:Bool {
        didSet {
            defaults.setBool(autoRestart, forKey: auto_restart_key)
        }
    }

    var animationSpeed:AnimationSpeed {
        didSet {
            defaults.setInteger(self.animationSpeed.rawValue, forKey: animation_speed_key)
        }
    }

    enum AnimationSpeed : Int {
        case slow = 0
        case normal = 1
        case fast = 2
        var speed:Double {
            switch self {
            case .slow:
                return 0.2
            case .normal:
                return 0.1
            case .fast:
                return 0.05
            }
        }
    }

    var animaitonDuration:Double {
        didSet {
            defaults.setDouble(self.animaitonDuration, forKey: animation_duration_key)
        }
    }

    var fontSize:Float {
        didSet {
            defaults.setFloat(self.fontSize, forKey: font_size_key)
        }
    }

    init () {
        defaults.registerDefaults([
            hint_key: "Hit it",
            candidates_key: ["Shake", "Pinch", "Hold"],
            skip_winner_key: true,
            auto_restart_key: true,
            animation_speed_key: AnimationSpeed.normal.rawValue,
            animation_duration_key: 0,
            font_size_key: 60.0
            ])

        self.candidates = defaults.objectForKey(candidates_key) as? [String] ?? []
        self.selectedCandidates = defaults.objectForKey(selected_candidates_key) as? [String] ?? []
        self.skipWinners = defaults.boolForKey(skip_winner_key)
        self.autoRestart = defaults.boolForKey(auto_restart_key)
        self.hint = defaults.stringForKey(hint_key) ?? ""

        self.animationSpeed = AnimationSpeed(rawValue: defaults.integerForKey(animation_speed_key))!
        self.animaitonDuration = defaults.doubleForKey(animation_duration_key)

        self.fontSize = defaults.floatForKey(font_size_key)
    }

}