//
//  ViewController.swift
//  ReactiveSwiftLondon
//
//  Created by Colin Eberhardt on 08/10/2014.
//  Copyright (c) 2014 Colin Eberhardt. All rights reserved.
//

import UIKit
import Accounts
import Social

enum TwitterInstantError: Int {
  case AccessDenied = 0, NoTwitterAccounts, InvalidResponse
}

class Tweet: NSObject {
  let profileImageUrl: String
  let username: String
  let status: String
  
  init(profileImageUrl: String, username: String, status: String) {
    self.profileImageUrl = profileImageUrl
    self.username = username
    self.status = status
  }
  
  class func tweetWithStatus(json: NSDictionary) -> Tweet {
    let status = json["text"] as String
    let user = json["user"] as NSDictionary
    let profileImageUrl = user["profile_image_url"] as String
    let username = user["screen_name"] as String
    return Tweet(profileImageUrl: profileImageUrl, username: username, status: status);
  }
}

class ViewController: UIViewController, UITableViewDataSource {
  
  private let ErrorDomain = "TwitterSearch"
  private let accountStore: ACAccountStore
  private let twitterAccountType: ACAccountType
  private var tweets: [Tweet]

  @IBOutlet weak var searchTextField: UITextField!
  @IBOutlet weak var tweetsTableView: UITableView!
  
  required init(coder aDecoder: NSCoder) {
    
    accountStore = ACAccountStore()
    twitterAccountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
    
    tweets = [Tweet]()
    
    super.init(coder: aDecoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
   
    tweetsTableView.dataSource = self
    tweetsTableView.estimatedRowHeight = 68.0
    tweetsTableView.rowHeight = UITableViewAutomaticDimension
    
    requestAccessToTwitterSignal()
      .then {
        self.searchTextField.rac_textSignal()
      }
      .filterAs {
        (text: NSString) -> Bool in
        text.length > 3
      }
      .throttle(0.5)
      .flattenMapAs {
        (text: NSString) -> RACStream in
        self.signalForSearchWithText(text)
      }
      .deliverOn(RACScheduler.mainThreadScheduler())
      .subscribeNextAs({
        (tweets: NSDictionary) in
        let statuses = tweets["statuses"] as [NSDictionary]
        self.tweets = statuses.map { Tweet.tweetWithStatus($0) }
        self.tweetsTableView.reloadData()
        self.tweetsTableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
        
      }, {
        (error) in
        println(error)
      })
  }
  
  private func requestAccessToTwitterSignal() -> RACSignal {
    
    let accessError = NSError.errorWithDomain(ErrorDomain, code: TwitterInstantError.AccessDenied.toRaw(), userInfo: nil)
    
    return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
      self.accountStore.requestAccessToAccountsWithType(self.twitterAccountType, options: nil) {
        (granted, _) -> Void in
        if granted {
          subscriber.sendNext(nil)
          subscriber.sendCompleted()
        } else {
          subscriber.sendError(accessError)
        }
      }
      return nil
    })
  }
  

  
  private func signalForSearchWithText(text: String) -> RACSignal {

    func requestforTwitterSearchWithText(text: String) -> SLRequest {
      let url = NSURL(string: "https://api.twitter.com/1.1/search/tweets.json")
      let params = ["q" : text, "count": "100", "lang" : "en"]
      return SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, URL: url, parameters: params)
    }
    
    let noAccountsError = NSError.errorWithDomain(ErrorDomain, code: TwitterInstantError.NoTwitterAccounts.toRaw(), userInfo: nil)
    
    let invalidResponseError = NSError.errorWithDomain(ErrorDomain, code: TwitterInstantError.InvalidResponse.toRaw(), userInfo: nil)
    
    return RACSignal.createSignal {
      subscriber -> RACDisposable! in
      
      let request = requestforTwitterSearchWithText(text)
      let twitterAccounts = self.accountStore.accountsWithAccountType(self.twitterAccountType)
      if twitterAccounts.count == 0 {
        subscriber.sendError(noAccountsError)
      } else {
        request.account = twitterAccounts[0] as ACAccount
        
        request.performRequestWithHandler {
          (data, response, _) -> Void in
          if response != nil && response.statusCode == 200 {
            let timelineData = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: nil)
            subscriber.sendNext(timelineData)
            subscriber.sendCompleted()
          } else {
            subscriber.sendError(invalidResponseError)
          }
        }
      }
      return nil
    }
  }
  
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return tweets.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as TweetTableViewCell
    cell.tweet = tweets[indexPath.row]
    return cell
  }

}

