//
//  TweetTableViewCell.swift
//  ReactiveSwiftLondon
//
//  Created by Colin Eberhardt on 08/10/2014.
//  Copyright (c) 2014 Colin Eberhardt. All rights reserved.
//

import Foundation

class TweetTableViewCell: UITableViewCell {
  
  // MARK: Outlets
  
  @IBOutlet weak var avatarImageView: UIImageView!
  @IBOutlet weak var statusTextLabel: UILabel!
  @IBOutlet weak var sentimentLabel: UILabel!
  @IBOutlet weak var sentimentIndicator: UIView!
  
  //MARK: Properties
  
  var tweet: Tweet? {
    didSet {
      if let hasTweet = tweet {
        statusTextLabel.text = hasTweet.status
        sentimentLabel.text = "@" + hasTweet.username
        
        rac_prepareForReuseSignal.subscribeNext {
          (any) in
          self.sentimentIndicator.backgroundColor = UIColor.clearColor()
        }

        RACSignal
          .interval(0.5, onScheduler: RACScheduler(priority: RACSchedulerPriorityBackground))
          .take(1)
          .takeUntil(rac_prepareForReuseSignal)
          .flattenMap {
            (next) -> RACStream in
            self.obtainSentimentSignal(hasTweet)
          }
          .deliverOn(RACScheduler.mainThreadScheduler())
          .subscribeNextAs {
            (sentiment: String) in
            NSNotificationCenter.defaultCenter().postNotificationName("sentiment", object: sentiment)
            self.sentimentIndicator.backgroundColor = self.sentimentToColor(sentiment)
          }
        
        avatarImageView.image = nil
        avatarImageSignal(hasTweet.profileImageUrl)
          .subscribeOn(RACScheduler(priority: RACSchedulerPriorityBackground))
          .takeUntil(rac_prepareForReuseSignal)
          .deliverOn(RACScheduler.mainThreadScheduler())
          .subscribeNextAs {
            (image: UIImage) in
            self.avatarImageView.image = image
          }
       
      } 
    }
  }
  
  private func sentimentToColor(sentiment: String) -> UIColor {
    switch sentiment {
    case "positive":
      return UIColor.greenColor()
    case "negative":
      return UIColor.redColor()
    case "neutral":
      return UIColor.yellowColor()
    default:
      return UIColor.clearColor()
    }
  }
  
  // MARK: Functions that create signals
  
  private func avatarImageSignal(imageUrl: String) -> RACSignal {
    return RACSignal.createSignal{
      (subscriber) -> RACDisposable! in
      let data = NSData(contentsOfURL: NSURL(string: imageUrl)!)
      let image = UIImage(data: data!)
      subscriber.sendNext(image)
      subscriber.sendCompleted()
      return nil
    }
  }
  
  private func obtainSentimentSignal(tweet: Tweet) -> RACSignal {
    return RACSignal.createSignal {
      (subscriber) -> RACDisposable! in
      
      let encodedSearchText = tweet.status.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
      let url = "https://loudelement-free-natural-language-processing-service.p.mashape.com/nlp-text/?text=" + encodedSearchText!
      
      let urlRequest = NSMutableURLRequest(URL: NSURL(string: url)!)
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
  
}