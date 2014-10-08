//
//  ViewController.swift
//  ReactiveSwiftLondon
//
//  Created by Colin Eberhardt on 08/10/2014.
//  Copyright (c) 2014 Colin Eberhardt. All rights reserved.
//

import UIKit
import Accounts

enum TwitterInstantError: Int {
  case AccessDenied = 0, NoTwitterAccounts, InvalidResponse
}

class ViewController: UIViewController, UITableViewDataSource {
  
  private let ErrorDomain = "TwitterSearch"
  private let accountStore: ACAccountStore
  private let twitterAccountType: ACAccountType

  @IBOutlet weak var searchTextField: UITextField!
  @IBOutlet weak var tweetsTableView: UITableView!
  
  required init(coder aDecoder: NSCoder) {
    
    accountStore = ACAccountStore()
    twitterAccountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
    
    super.init(coder: aDecoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
   
    tweetsTableView.dataSource = self
    
    requestAccessToTwitterSignal().then {
      self.searchTextField.rac_textSignal()
    }.subscribeNextAs {
      (text: String) in
      println(text)
    }
    
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
  
  /*- (RACSignal *)requestAccessToTwitterSignal {
  
  // 1 - define an error
  NSError *accessError = [NSError errorWithDomain:RWTwitterInstantDomain
  code:RWTwitterInstantErrorAccessDenied
  userInfo:nil];
  
  // 2 - create the signal
  @weakify(self)
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
  // 3 - request access to twitter
  @strongify(self)
  [self.accountStore
  requestAccessToAccountsWithType:self.twitterAccountType
  options:nil
  completion:^(BOOL granted, NSError *error) {
  // 4 - handle the response
  if (!granted) {
  [subscriber sendError:accessError];
  } else {
  [subscriber sendNext:nil];
  [subscriber sendCompleted];
  }
  }];
  return nil;
  }];
  }*/

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 10
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell
    
    return cell
  }

}

