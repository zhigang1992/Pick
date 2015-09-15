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
let winners_key = "winners"
let skip_winner_key = "skipCandidate"
let auto_restart_key = "autoRestart"

class DataHolder {
    static let shared = DataHolder()

    let defaults = NSUserDefaults.standardUserDefaults()

    var hint:String

    var candidates:[String] {
        didSet {
            defaults.setObject(candidates, forKey: candidates_key)
        }
    }

    var selectedCandidates:[String] {
        didSet {
            defaults.setObject(selectedCandidates, forKey: winners_key)
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

    init () {
        defaults.registerDefaults([
            hint_key: "Hit it",
            candidates_key: ["Shake", "Pinch", "Hold"],
            skip_winner_key: true,
            auto_restart_key: true
            ])

        self.candidates = defaults.objectForKey(candidates_key) as? [String] ?? []
        self.selectedCandidates = defaults.objectForKey(winners_key) as? [String] ?? []
        self.skipWinners = defaults.boolForKey(skip_winner_key)
        self.autoRestart = defaults.boolForKey(auto_restart_key)
        self.hint = defaults.stringForKey(hint_key) ?? ""
    }

}