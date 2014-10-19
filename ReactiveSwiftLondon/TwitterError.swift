//
//  TwitterError.swift
//  ReactiveSwiftLondon
//
//  Created by Colin Eberhardt on 10/10/2014.
//  Copyright (c) 2014 Colin Eberhardt. All rights reserved.
//

import Foundation

// an enumeration that is used for generating NSError codes
enum TwitterInstantError: Int {
  case AccessDenied = 0, NoTwitterAccounts, InvalidResponse
  
  func toError() -> NSError {
    return NSError(domain:"TwitterSearch", code: self.rawValue, userInfo: nil)
  }
}