//
//  TweetTableViewCell.swift
//  ReactiveSwiftLondon
//
//  Created by Colin Eberhardt on 08/10/2014.
//  Copyright (c) 2014 Colin Eberhardt. All rights reserved.
//

import Foundation

class TweetTableViewCell: UITableViewCell {
  
  @IBOutlet weak var avatarImageView: UIImageView!
  @IBOutlet weak var statusTextLabel: UILabel!
  @IBOutlet weak var sentimentLabel: UILabel!
  
  var tweet: Tweet? {
    didSet {
      if let hasTweet = tweet {
        statusTextLabel.text = hasTweet.status
        
        rac_prepareForReuseSignal.subscribeNext {
          (any) in
          self.sentimentLabel.text = ""
        }

        RACSignal
          .interval(0.5, onScheduler: RACScheduler(priority: RACSchedulerPriorityBackground))
          .take(1)
          .takeUntil(rac_prepareForReuseSignal)
          .flattenMap {
            (next) -> RACStream in
            self.obtainSentimentSignal2(hasTweet)
          }
          .deliverOn(RACScheduler.mainThreadScheduler())
          .subscribeNextAs {
            (sentiment: String) in
            self.sentimentLabel.text = sentiment
          }
        
      } 
    }
  }
  
  private func obtainSentimentSignal(tweet: Tweet) -> RACSignal {
    return RACSignal.createSignal {
      (subscriber) -> RACDisposable! in
      subscriber.sendNext("negative")
      subscriber.sendCompleted()
      return nil
    }
  }
  
  
  private func obtainSentimentSignal2(tweet: Tweet) -> RACSignal {
    return RACSignal.createSignal {
      (subscriber) -> RACDisposable! in
      
      let encodedSearchText = tweet.status.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
      println(encodedSearchText)
      let url = "https://loudelement-free-natural-language-processing-service.p.mashape.com/nlp-text/?text=" + encodedSearchText!
      
      let urlRequest = NSMutableURLRequest(URL: NSURL(string: url))
      urlRequest.HTTPMethod = "GET"
      urlRequest.addValue("JepIlTfFXKmsh6Xzs8F3FQVfJ1Mbp1qCPfAjsn5b5GxBilACc5", forHTTPHeaderField:"X-Mashape-Key")
      
      let queue = NSOperationQueue()
      NSURLConnection.sendAsynchronousRequest(urlRequest, queue: queue, completionHandler: {
        (response, data, error) -> Void in
        if error == nil {
          let json = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: nil) as NSDictionary
          subscriber.sendNext(json["sentiment-text"])
          subscriber.sendCompleted()
        } else {
          subscriber.sendError(error)
        }
      })
      
      return nil
    }
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  
}