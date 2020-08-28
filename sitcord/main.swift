//
//  main.swift
//  sitcord
//
//  Created by Kyle Brodie, Jonathan Ming on 2020-08-28.
//  Copyright © 2020 Reveel, LLC. All rights reserved.
//
import Foundation
import AppKit
import Darwin

setbuf(__stdoutp, nil);

func automateDiscord(sit: Bool) -> Bool {
    print("Telling automateDiscord to", sit ? "sit" : "stand")

    let jsLocation = Bundle.main.resourceURL?.appendingPathComponent("./bin/automateDiscord.js")
    
    let task = Process()
    let stdoutP = Pipe()
    let stderrP = Pipe()
    task.standardOutput = stdoutP;
    task.standardError = stderrP;
    task.executableURL = URL.init(fileURLWithPath: "/usr/bin/env", isDirectory: false)
    task.arguments = ["node", jsLocation?.absoluteString ?? "./automateDiscord.js", "--", sit ? "--sit" : "--stand"]
    task.launch()
    task.waitUntilExit()

    let stdoutData = stdoutP.fileHandleForReading.readDataToEndOfFile()
    let stdoutStr = String.init(data: stdoutData, encoding: String.Encoding.utf8)
    print(stdoutStr ?? "Failed to decode automateDiscord.js STDOUT to UTF-8")

    let stderrData = stderrP.fileHandleForReading.readDataToEndOfFile()
    let stderrStr = String.init(data: stderrData, encoding: String.Encoding.utf8)
    print(stderrStr ?? "Failed to decode automateDiscord.js STDERR to UTF-8", stderr)

    return task.terminationStatus == 0
}

class SitcordObserver {
    var sit: Bool

    init() {
        sit = true
    }

    @objc
    func sleepFn() {
        let result = automateDiscord(sit: false)
        if !result {
            print("Failed to automate discord. Stopping...")
            exit(1)
        } else {
            sit = false
        }
    }

    @objc
    func wakeFn() {
        let result = automateDiscord(sit: true)
        if !result {
            print("Failed to automate discord. Stopping...")
            exit(1)
        }
        else {
            sit = true
        }
    }

    @objc
    func status() {
        print("Sitcord current state:", sit ? "sit" : "stand")
        let result = automateDiscord(sit: sit)
        if !result {
            print("Failed to automate discord. Stopping...")
            exit(1)
        }
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
