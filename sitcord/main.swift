//
//  main.swift
//  sitcord
//
//  Created by Kyle Brodie, Jonathan Ming on 2020-08-28.
//  Copyright © 2020 Reveel, LLC. All rights reserved.
//
import Foundation
import AppKit

func automateDiscord(sit: Bool) -> Bool {
    print("Telling automateDiscord to", sit ? "sit" : "stand")
    let task = Process()
    let stdout = Pipe()
    task.standardOutput = stdout;
    task.executableURL = URL.init(fileURLWithPath: "/usr/bin/env", isDirectory: false)
    task.arguments = ["node", "./automateDiscord.js", "--", sit ? "--sit" : "--stand"]
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus == 0
}

class SitcordObserver {
    var state: String

    init() {
        state = "awake"
    }

    @objc
    func sleepFn() {
        state = "asleep"
        let result = automateDiscord(sit: false)
        print(result)
    }

    @objc
    func wakeFn() {
        state = "awake"
        let result = automateDiscord(sit: true)
        print(result)
    }

    @objc
    func status() {
        print(state)
    }
}

func main() {
    print("Starting...")
    let obs = SitcordObserver()

    let workspaceNotifCenter = NSWorkspace.shared.notificationCenter;
    workspaceNotifCenter.addObserver(obs, selector: #selector(SitcordObserver.sleepFn), name: NSWorkspace.willSleepNotification, object: nil)
    workspaceNotifCenter.addObserver(obs, selector: #selector(SitcordObserver.wakeFn), name: NSWorkspace.didWakeNotification, object: nil)

    let distribNotifCenter = DistributedNotificationCenter.default;
    distribNotifCenter.addObserver(obs, selector: #selector(SitcordObserver.sleepFn), name: NSNotification.Name("com.apple.screenIsLocked"), object: nil)
    distribNotifCenter.addObserver(obs, selector: #selector(SitcordObserver.wakeFn), name: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil)
    
    // print status to keep app alive
    Timer.scheduledTimer(timeInterval: 60, target: obs, selector: #selector(SitcordObserver.status), userInfo: nil, repeats: true)
    RunLoop.current.run()
}

public func registerSigint() -> DispatchSourceSignal {
    signal(SIGINT, SIG_IGN)
    let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    sigintSrc.setEventHandler {
        print("Stopping...")
        exit(0)
    }
    sigintSrc.resume()
    return sigintSrc
}

let source = registerSigint()
main()
