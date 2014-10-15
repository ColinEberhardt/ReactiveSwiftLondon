//
//  Tweet.swift
//  ReactiveSwiftLondon
//
//  Created by Colin Eberhardt on 10/10/2014.
//  Copyright (c) 2014 Colin Eberhardt. All rights reserved.
//

import Foundation


struct Tweet {
  let profileImageUrl: String
  let username: String
  let status: String
  
  init(profileImageUrl: String, username: String, status: String) {
    self.profileImageUrl = profileImageUrl
    self.username = username
    self.status = status
  }
  
  init(json: NSDictionary) {
    let status = json["text"] as String
    let user = json["user"] as NSDictionary
    let profileImageUrl = user["profile_image_url"] as String
    let username = user["screen_name"] as String
    self.init(profileImageUrl: profileImageUrl, username: username, status: status);
  }
}