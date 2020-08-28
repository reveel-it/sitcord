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
    print(NSDate(), "Telling automateDiscord to", sit ? "sit" : "stand")

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

    print(NSDate(), "Finished running task")

    let stdoutData = stdoutP.fileHandleForReading.readDataToEndOfFile()
    let stdoutStr = String.init(data: stdoutData, encoding: String.Encoding.utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    print(NSDate(), "node stdout:", stdoutStr ?? "Failed to decode automateDiscord.js STDOUT to UTF-8")

    let stderrData = stderrP.fileHandleForReading.readDataToEndOfFile()
    let stderrStr = String.init(data: stderrData, encoding: String.Encoding.utf8)?.trimmingCharacters(in: .whitespacesAndNewlines);
    print(NSDate(), "node stderr:", stderrStr ?? "Failed to decode automateDiscord.js STDERR to UTF-8")

    return task.terminationStatus == 0
}

class SitcordObserver {
    var sit: Bool

    init() {
        sit = true
    }

    func sit(n: Notification) {
        print(NSDate(), "RECV:", n.name.rawValue)
        let result = automateDiscord(sit: true)
        if !result {
            print(NSDate(), "Failed to automate discord. Stopping...")
            exit(1)
        } else {
            sit = true
        }
    }

    func stand(n: Notification) {
        print(NSDate(),"RECV:", n.name.rawValue)
        let result = automateDiscord(sit: false)
        if !result {
            print(NSDate(), "Failed to automate discord. Stopping...")
            exit(1)
        } else {
            sit = false
        }
    }

    func status(t: Timer) {
        print(NSDate(), "Sitcord current state:", sit ? "sit" : "stand")
    }
}

func main() {
    print(NSDate(), "Starting...")
    let obs = SitcordObserver()
    let workspaceNotifCenter = NSWorkspace.shared.notificationCenter;
    let distribNotifCenter = DistributedNotificationCenter.default()

    workspaceNotifCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: nil, using: obs.sit)
    distribNotifCenter.addObserver(forName: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil, queue: nil, using: obs.sit)

    workspaceNotifCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: nil, using: obs.stand)
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
