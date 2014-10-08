//
//  ViewController.swift
//  ReactiveSwiftLondon
//
//  Created by Colin Eberhardt on 08/10/2014.
//  Copyright (c) 2014 Colin Eberhardt. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource {

  @IBOutlet weak var searchTextField: UITextField!
  @IBOutlet weak var tweetsTableView: UITableView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
   
    tweetsTableView.dataSource = self
    
    searchTextField.rac_textSignal().subscribeNextAs {
      (text: String) in
      println(text)
    }
  }

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 10
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell
    
    return cell
  }

}

