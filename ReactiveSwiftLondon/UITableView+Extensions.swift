//
//  UITableView+Extensions.swift
//  ReactiveSwiftLondon
//
//  Created by Colin Eberhardt on 10/10/2014.
//  Copyright (c) 2014 Colin Eberhardt. All rights reserved.
//

import Foundation

extension UITableView {
  func scrollToTop() {
    self.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
  }
}

extension UIColor {
  class func lightRedColor() -> UIColor {
    return UIColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 0.3)
  }
}
extension NSJSONSerialization {
  class func parseJSONToDictionary(data: NSData) -> NSDictionary {
    return JSONObjectWithData(data, options: .AllowFragments, error: nil) as NSDictionary
  }
}