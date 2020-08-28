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
setbuf(__stderrp, nil);

func automateDiscord(sit: Bool) -> Bool {
    print(NSDate(), sit ? "sit" : "stand", "-> automateDiscord.js")

    let bundleLocation = Bundle.main.resourceURL?.standardizedFileURL ?? URL.init(fileURLWithPath: ".", isDirectory: true).standardizedFileURL
    let jsLocation = bundleLocation.appendingPathComponent("automateDiscord.js")

    let task = Process()
    let stdoutP = Pipe()
    let stderrP = Pipe()
    task.standardOutput = stdoutP;
    task.standardError = stderrP;
    task.executableURL = URL.init(fileURLWithPath: "/usr/bin/env", isDirectory: false)
    task.arguments = ["node", jsLocation.path, sit ? "--sit" : "--stand"]
    task.launch()
    task.waitUntilExit()

    let stdoutData = stdoutP.fileHandleForReading.readDataToEndOfFile()
    let stdoutStr = String.init(data: stdoutData, encoding: String.Encoding.utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    if !(stdoutStr?.isEmpty ?? true) {
        print(NSDate(), "automateDiscord.js ->", stdoutStr ?? "")
    }
    else {
        let stderrData = stderrP.fileHandleForReading.readDataToEndOfFile()
        let stderrStr = String.init(data: stderrData, encoding: String.Encoding.utf8)?.trimmingCharacters(in: .whitespacesAndNewlines);
        if !(stderrStr?.isEmpty ?? true) {
            print(NSDate(), "automateDiscord.js ->", stdoutStr ?? "")
        }
    }

    return task.terminationStatus == 0
}

class SitcordObserver {
    var sit: Bool

    init() {
        sit = true
    }

    func sit(n: Notification) {
        let result = automateDiscord(sit: true)
        if !result {
            print(NSDate(), "Failed to automate Discord. Stopping...")
            exit(1)
        } else {
            sit = true
        }
    }

    func stand(n: Notification) {
        let result = automateDiscord(sit: false)
        if !result {
            print(NSDate(), "Failed to automate Discord. Stopping...")
            exit(1)
        } else {
            sit = false
        }
    }

    func status(t: Timer) {
        print(NSDate(), sit ? "sitting" : "standing")
    }
}

func main() {
    print(NSDate(), "Starting...")
    let obs = SitcordObserver()
    let distribNotifCenter = DistributedNotificationCenter.default()

    distribNotifCenter.addObserver(forName: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil, queue: nil, using: obs.sit)
    distribNotifCenter.addObserver(forName: NSNotification.Name("com.apple.screenIsLocked"), object: nil, queue: nil, using: obs.stand)
    
    // print status to keep app alive
    Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: obs.status)
    RunLoop.current.run()
}

public func registerSigint() -> DispatchSourceSignal {
    signal(SIGINT, SIG_IGN)
    let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    sigintSrc.setEventHandler {
        print(NSDate(), "SIGINT received. Stopping...")
        exit(0)
    }
    sigintSrc.resume()
    return sigintSrc
}

let source = registerSigint()
main()
