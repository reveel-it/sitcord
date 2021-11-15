//  main.swift
//  sitcord
//
//  Created by Kyle Brodie, Arte Ebrahimi, Jonathan Ming
//  Copyright © 2021 Reveel, LLC. All rights reserved.
//
import AppKit
import Darwin
import Foundation

setbuf(__stdoutp, nil)
setbuf(__stderrp, nil)

func automateDiscord(server: String, sit: Bool) -> Bool {
    NSLog("Automate Discord %", sit ? "sit" : "stand")
    print(NSDate(), sit ? "sit" : "stand", "-> automateDiscord")

    let bundleLocation = Bundle.main.resourceURL?.standardizedFileURL ?? URL(fileURLWithPath: ".", isDirectory: true).standardizedFileURL
    let jsLocation = bundleLocation.appendingPathComponent("automateDiscord.js")

    let task = Process()
    let stdoutP = Pipe()
    let stderrP = Pipe()
    task.standardOutput = stdoutP
    task.standardError = stderrP
    task.executableURL = URL(fileURLWithPath: "/usr/bin/env", isDirectory: false)
    task.arguments = ["node", jsLocation.path, sit ? "--sit" : "--stand", "--port=54321", "--server='\(server)'"]
    // task.launchPath = "/bin/zsh"
    // task.arguments = ["-c", "node \(jsLocation.path) \(sit ? "--sit" : "--stand") --port 54321 --server '\(server)'"]
    task.launch()
    task.waitUntilExit()

    let stdoutData = stdoutP.fileHandleForReading.readDataToEndOfFile()
    let stdoutStr = String(data: stdoutData, encoding: String.Encoding.utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    if !(stdoutStr?.isEmpty ?? true) {
        print(NSDate(), "automateDiscord.js ->", stdoutStr ?? "")
    } else {
        let stderrData = stderrP.fileHandleForReading.readDataToEndOfFile()
        let stderrStr = String(data: stderrData, encoding: String.Encoding.utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        NSLog("ERROR: %", stderrStr ?? "")
        NSLog(stderrStr!)
        if !(stderrStr?.isEmpty ?? true) {
            print(NSDate(), "automateDiscord.js ->", stdoutStr ?? "")
        }
    }

    return task.terminationStatus == 0
}

func executeAppleScript(script: String) -> Bool {
    var error: NSDictionary?
    if let scriptObject = NSAppleScript(source: script) {
        if scriptObject.executeAndReturnError(&error).stringValue != nil {
            return true
        } else if error != nil {
            print("error: ", error!)
            return false
        }
    }

    return false
}

class SitcordObserver {
    var sit: Bool
    var server: String

    init(iServer: String) {
        sit = true
        server = iServer
    }

    func sit(n _: Notification) {
        // let result = executeAppleScript(script: """
        // tell application "System Events" to tell process "Discord"
        //     keystroke "k" using {command down}
        //     delay 0.2
        //     keystroke "*"
        //     delay 0.5
        //     key code 36
        //     delay 0.3

        //     keystroke "k" using {command down}
        //     delay 0.1
        //     keystroke "!g"
        //     delay 0.1
        //     key code 36
        // end tell
        // """)
        let result = automateDiscord(server: server, sit: true)
        if !result {
            print(NSDate(), "Failed to automate Discord. Stopping...")
            exit(1)
        } else {
            sit = true
        }
    }

    func stand(n _: Notification) {
        // let result = executeAppleScript(script: """
        // tell application "System Events" to tell process "Discord"
        //     keystroke "k" using {command down}
        //     delay 0.2
        //     keystroke "@sitcord-do-not-friend-me"
        //     delay 0.2
        //     key code 36
        //     delay 0.2

        //     keystroke "'" using {control down}
        //     delay 0.5

        //     keystroke "m" using {command down, shift down}
        // end tell
        // """)
        let result = automateDiscord(server: server, sit: false)
        if !result {
            print(NSDate(), "Failed to automate Discord. Stopping...")
            exit(1)
        } else {
            sit = false
        }
    }

    func status(t _: Timer) {
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
        ) { _, change in
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

    let config = NSWorkspace.OpenConfiguration()
    config.arguments = ["--remote-debugging-port=54321"]

    var discord: NSRunningApplication?

    NSWorkspace.shared.openApplication(at: discordUrl, configuration: config) { runningApp, _ -> Void in
        discord = runningApp
        DiscordTerminatedObserver(object: runningApp!)
    }

    let obs = SitcordObserver(iServer: "Focus Dev")
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
