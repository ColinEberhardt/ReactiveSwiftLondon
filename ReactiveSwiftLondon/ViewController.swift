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


class ViewController: UIViewController, UITableViewDataSource {

  //MARK: outlets
  
  @IBOutlet weak var searchTextField: UITextField!
  @IBOutlet weak var tweetsTableView: UITableView!
  
  //MARK: properties
  
  private let accountStore: ACAccountStore
  private let twitterAccountType: ACAccountType
  private var tweets = [Tweet]()
  
  //MARK: ViewController lifecycle
  
  required init(coder aDecoder: NSCoder) {
    
    accountStore = ACAccountStore()
    twitterAccountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
    
    super.init(coder: aDecoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
   
    tweetsTableView.dataSource = self
    tweetsTableView.estimatedRowHeight = 68.0
    tweetsTableView.rowHeight = UITableViewAutomaticDimension
    
    self.searchTextField.rac_textSignal()
      .mapAs {
        (text: NSString) -> UIColor in
        text.length <= 3 ? UIColor.lightRedColor() : UIColor.whiteColor()
      }
      .setKeyPath("backgroundColor", onObject: searchTextField)
    
    requestAccessToTwitterSignal()
      .then {
        self.searchTextField.rac_textSignal()
      }
      .filterAs {
        (text: NSString) -> Bool in
        text.length > 3
      }
      .throttle(0.5)
      .doNext {
        (any) in
        NSNotificationCenter.defaultCenter().postNotificationName("sentiment", object: "reset")
      }
      .flattenMapAs {
        (text: NSString) -> RACStream in
        self.signalForSearchWithText(text)
      }
      .deliverOn(RACScheduler.mainThreadScheduler())
      .subscribeNextAs({
        (tweets: NSDictionary) in
        let statuses = tweets["statuses"] as [NSDictionary]
        self.tweets = statuses.map { Tweet(json: $0) }
        self.tweetsTableView.reloadData()
        self.tweetsTableView.scrollToTop()
      }, {
        (error) in
        println(error)
      })
  }
  
  //MARK: Functions that create signals
  
  private func requestAccessToTwitterSignal() -> RACSignal {
    
    return RACSignal.createSignal {
      (subscriber) -> RACDisposable! in
      self.accountStore.requestAccessToAccountsWithType(self.twitterAccountType, options: nil) {
        (granted, _) -> Void in
        if granted {
          subscriber.sendNext(nil)
          subscriber.sendCompleted()
        } else {
          subscriber.sendError(TwitterInstantError.AccessDenied.toError())
        }
      }
      return nil
    }
  }
  
  private func getTwitterAccount() -> ACAccount? {
    let twitterAccounts = self.accountStore.accountsWithAccountType(self.twitterAccountType) as [ACAccount]
    if twitterAccounts.count == 0 {
      return nil
    } else {
      return twitterAccounts[0]
    }
  }
  
  private func signalForSearchWithText(text: String) -> RACSignal {

    func requestforSearchText(text: String) -> SLRequest {
      let url = NSURL(string: "https://api.twitter.com/1.1/search/tweets.json")
      let params = [
        "q" : text,
        "count": "100",
        "lang" : "en"
      ]
      return SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, URL: url, parameters: params)
    }
    
    return RACSignal.createSignal {
      subscriber -> RACDisposable! in
      
      let request = requestforSearchText(text)
      let maybeTwitterAccount = self.getTwitterAccount()
      
      if let twitterAccount = maybeTwitterAccount {
        request.account = twitterAccount
        request.performRequestWithHandler {
          (data, response, _) -> Void in
          if response != nil && response.statusCode == 200 {
            let timelineData = NSJSONSerialization.parseJSONToDictionary(data)
            subscriber.sendNext(timelineData)
            subscriber.sendCompleted()
          } else {
            subscriber.sendError(TwitterInstantError.InvalidResponse.toError())
          }
        }
      } else {
        subscriber.sendError(TwitterInstantError.NoTwitterAccounts.toError())
      }
      
      return nil
    }
  }
  
  //MARK: Table view datasource methods
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return tweets.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as TweetTableViewCell
    cell.tweet = tweets[indexPath.row]
    return cell
  }

}

