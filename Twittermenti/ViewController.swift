//
//  ViewController.swift
//  Twittermenti
//
//  Created by Amerigo Mancino on 17/09/2019.
//  Copyright © 2019 Amerigo Mancino. All rights reserved.
//

import UIKit
import SwifteriOS
import CoreML
import SwiftyJSON

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sentimentLabel: UILabel!
    
    let tweetCount = 100
    
    let sentimentClassifier = TweetSentimentClassifier()
    
    // Instantiation using Twitter's OAuth Consumer Key and secret
    var swifter: Swifter!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // keep api keys secure by reading them from an external plist file
        swifter = Swifter(consumerKey: valueForAPIKey(named: "ApiKey"), consumerSecret: valueForAPIKey(named: "ApiSecret"))
        
        textField.delegate = self
        
        // add observers for adjusting the constraints when the keyboard raises up or it's dismissed
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // add selector for dismissing the keyboard when tapping outside
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)

    }
    
    func fetchTweets() {
        // if the search text is not empty...
        if let searchText = textField.text {
            // ask twitter api for 100 english tweets over a given topic
            swifter.searchTweet(using: searchText, lang: "en", count: tweetCount, tweetMode: .extended, success: { (results, metadata) in
                
                // new array of strings containing all the tweets we get back
                var tweets = [TweetSentimentClassifierInput]()
                
                for i in 0..<self.tweetCount {
                    if let tweet = results[i]["full_text"].string {
                        let tweetForClassification = TweetSentimentClassifierInput(text: tweet)
                        tweets.append(tweetForClassification)
                    }
                }
                
                self.makePrediction(with: tweets)
                
                
            }) { (error) in
                print("There was an error with the Twitter API request, \(error)")
            }
        }
    }
    
    func makePrediction(with tweets: [TweetSentimentClassifierInput]) {
        do {
            // make a prediction for every element in the array of tweets
            let predictions = try self.sentimentClassifier.predictions(inputs: tweets)
            
            // calculate the sentiment for all the predictions
            var sentimentScore = 0
            
            for prediction in predictions {
                let sentiment = prediction.label
                if sentiment == "Pos" {
                    sentimentScore += 1
                } else if sentiment == "Neg" {
                    sentimentScore -= 1
                }
            }

            updateUI(with: sentimentScore)
            
        } catch {
            print("There was an error with making a prediction, \(error)")
        }
    }
    
    // change the UI emoji
    func updateUI(with sentimentScore: Int) {
        if sentimentScore > 30 {
            self.sentimentLabel.text = "😍"
        } else if sentimentScore > 10 {
            self.sentimentLabel.text = "🙂"
        } else if sentimentScore == 0 {
            self.sentimentLabel.text = "😐"
        } else if sentimentScore > -10 {
            self.sentimentLabel.text = "🙁"
        } else if sentimentScore > -20 {
            self.sentimentLabel.text = "😡"
        } else {
            self.sentimentLabel.text = "🤮"
        }
    }
    
    
    @IBAction func predictPressed(_ sender: Any) {
        fetchTweets()
    }
    
    // MARK: - HANDLE THE API KEYS
    
    // The routine looks for the Secrets.plist file in the application’s resource bundle,
    // loads it as an NSDictionary and then looks up the value for the given key as a String.
    func valueForAPIKey(named keyname:String) -> String {
        let filePath = Bundle.main.path(forResource: "Secrets", ofType: "plist")
        let plist = NSDictionary(contentsOfFile:filePath!)
        let value = plist?.object(forKey: keyname) as! String
        return value
    }
    
    // MARK: - KEYBOARD DELEGATE METHODS AND SELECTORS
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height - 100
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    // triggers when the user presses the return button on the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        self.fetchTweets()
        return false
    }
    
    // triggers when the user tap outside the keyboard and dismiss it
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

