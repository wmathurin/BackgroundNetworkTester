//
//  ViewController.swift
//  BackgroundNetworkTester
//
//  Created by Wolfgang Mathurin on 6/16/15.
//  Copyright (c) 2015 salesforce. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    var counter  : Int = 0;
    var running : Bool = false;
    var bgTask : UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid;

    @IBOutlet weak var counterLabel: UILabel!
    @IBOutlet weak var startStopButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = UIRectEdge.None;
        
        // Update UI
        self.updateUI();
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func onResetClick(sender: AnyObject) {
        self.running = false;
        self.counter = 0;
        self.updateUI();
    }
    
    @IBAction func onStartStopClick(sender: AnyObject) {
        self.running = !self.running;
        if (self.running) {
            self.startTask();
        }
        self.updateUI();
    }
    
    func updateUI() {
        dispatch_async(dispatch_get_main_queue(), {
            self.startStopButton.setTitle(self.running ? "Stop" : "Start", forState: UIControlState.Normal);
            self.counterLabel.text = String(self.counter);
        });
    }

    func startTask() {
        self.bgTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            UIApplication.sharedApplication().endBackgroundTask(self.bgTask);
            self.bgTask = UIBackgroundTaskInvalid;
        });
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            while (self.running) {
                self.doNetworkCall();
                self.counter++;
                self.updateUI();
                NSThread.sleepForTimeInterval(1.0);
            }
            self.running = false;
            self.updateUI();
        });
    }
    
    func doNetworkCall() {
        var semaphore : dispatch_semaphore_t = dispatch_semaphore_create(0);
        
        var failBlock : SFRestFailBlock = { (e) in
            NSLog("Network call \(self.counter) failed with error \(e)");
            self.running = false;
            dispatch_semaphore_signal(semaphore);
        };
        
        var completeBlock : SFRestDictionaryResponseBlock  = { (d) in
            NSLog("Network call \(self.counter) succeeded with response \(d)");
            dispatch_semaphore_signal(semaphore);
        };

        NSLog("Network call \(self.counter) sent");
        var query : String = "SELECT Id FROM Contact ORDER BY LastName LIMIT 1";
        var request = SFRestAPI.sharedInstance().performSOQLQuery(query, failBlock: failBlock, completeBlock: completeBlock);

        // Block until network call completes or fails
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    }
}

