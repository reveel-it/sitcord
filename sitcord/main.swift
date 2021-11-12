//
//  main.swift
//  sitcord
//
//  Created by Kyle Brodie, Arte Ebrahimi, Jonathan Ming
//  Copyright © 2021 Reveel, LLC. All rights reserved.
//
import Foundation
import AppKit
import Darwin

setbuf(__stdoutp, nil);
setbuf(__stderrp, nil);

func automateDiscord(server: String, sit: Bool) -> Bool {
    print(NSDate(), sit ? "sit" : "stand", "-> automateDiscord")

    let bundleLocation = Bundle.main.resourceURL?.standardizedFileURL ?? URL.init(fileURLWithPath: ".", isDirectory: true).standardizedFileURL
    let jsLocation = bundleLocation.appendingPathComponent("automateDiscord.js")

    let task = Process()
    let stdoutP = Pipe()
    let stderrP = Pipe()
    task.standardOutput = stdoutP;
    task.standardError = stderrP;
    task.executableURL = URL.init(fileURLWithPath: "/usr/bin/env", isDirectory: false)
    task.arguments = ["node", jsLocation.path, sit ? "--sit" : "--stand", "--port=54321", "--server='\(server)'"]
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
    var server: String

    init(iServer: String) {
        sit = true
        server = iServer
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

class DiscordTerminatedObserver: NSObject {
    @objc var objectToObserve: NSRunningApplication
    var observation: NSKeyValueObservation?

    init(object: NSRunningApplication) {
        objectToObserve = object
        super.init()

        observation = observe(
            \.objectToObserve.isTerminated,
            options: [.initial, .new]
        ) { object, change in
            print(NSDate(), "Discord isTerminated changed to: \(change.newValue!)")
            if change.newValue == true {
                print(NSDate(), "Discord terminated. Stopping...")
                exit(0)
            }
        }
    }
}

func main() {
    print(NSDate(), "Starting...")

    guard let discordUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.hnc.Discord") else {
        print(NSDate(), "Can't locate Discord app; is it installed?")
        return
    }

    let discord = NSWorkspace.shared.openApplication(at: discordUrl, configuration: NSWorkspace.OpenConfiguration(arguments: ["--remote-debugging-port=54321"]))
    let discordTermObs = DiscordTerminatedObserver(object: discord)

    let obs = SitcordObserver("Focus Dev")
    let distribNotifCenter = DistributedNotificationCenter.default()

    distribNotifCenter.addObserver(forName: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil, queue: nil, using: obs.sit)
    distribNotifCenter.addObserver(forName: NSNotification.Name("com.apple.screenIsLocked"), object: nil, queue: nil, using: obs.stand)
    
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
