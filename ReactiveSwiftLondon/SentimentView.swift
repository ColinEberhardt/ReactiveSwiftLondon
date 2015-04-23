//
//  SentimentView.swift
//  ReactiveSwiftLondon
//
//  Created by Colin Eberhardt on 10/10/2014.
//  Copyright (c) 2014 Colin Eberhardt. All rights reserved.
//

import Foundation

// A simple view that shows a summary of the current sentiment value
class SentimentView: UIView {
  
  var positive = 0, negative = 0, neutral = 0
  let positiveLayer: CALayer, negativeLayer: CALayer, neutralLayer: CALayer
  let positiveFace: UIImageView, negativeFace: UIImageView, neutralFace: UIImageView, waitingFace: UIImageView

  required init(coder aDecoder: NSCoder) {
    positiveLayer = CALayer()
    positiveLayer.backgroundColor = UIColor.greenColor().CGColor
    negativeLayer = CALayer()
    negativeLayer.backgroundColor = UIColor.redColor().CGColor
    neutralLayer = CALayer()
    neutralLayer.backgroundColor = UIColor.yellowColor().CGColor
    
    func createImage(name: String) -> UIImageView {
      let imageView = UIImageView(image: UIImage(named: name))
      imageView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
      return imageView
    }
    positiveFace = createImage("positive")
    negativeFace = createImage("negative")
    neutralFace = createImage("neutral")
    waitingFace = createImage("neutral")
    
    super.init(coder: aDecoder)
    
    self.layer.addSublayer(neutralLayer)
    self.layer.addSublayer(negativeLayer)
    self.layer.addSublayer(positiveLayer)
    
    self.addSubview(positiveFace)
    self.addSubview(negativeFace)
    self.addSubview(neutralFace)
    self.addSubview(waitingFace)
   
    // subscribe to sentiment notifications
    NSNotificationCenter.defaultCenter().rac_addObserverForName("sentiment", object: nil)
      .subscribeNextAs {
        (notification: NSNotification) -> () in
        let sentiment = notification.object as! String
        switch sentiment {
        case "positive":
          self.positive++
        case "negative":
          self.negative++
        case "neutral":
          self.neutral++
        case "reset":
          self.positive = 0
          self.negative = 0
          self.neutral = 0
        default: ()
        }
        self.updateLayerBounds()
      }
    
    updateLayerBounds()
  }
  
  private func updateLayerBounds() {
    
    func scale(domainMin: Double, domainMax: Double, screenMin: Double, screenMax: Double)(pt: Double) -> CGFloat {
      if domainMin == domainMax {
        return 0.0
      } else {
        let value = ((pt - domainMin) / (domainMax - domainMin)) * (screenMax - screenMin) + screenMin
        return CGFloat(value)
      }
    }
    
    func delta(scale:(Double) -> CGFloat)(pt1: Double, pt2: Double) -> CGFloat {
      return scale(pt1) - scale(pt2)
    }

    let maxValue = max(positive, negative, neutral)
    let xscale = scale(0, Double(maxValue), 35, Double(self.bounds.width - 35))
    let yscale = scale(0, 3, 0, Double(self.bounds.height))
    
    let xdelta = delta(xscale)
    
    positiveLayer.frame = CGRect(x: xscale(pt: 0), y: yscale(pt: 0),
      width: xdelta(pt1: Double(positive), pt2: 0.0), height: yscale(pt: 1))
    neutralLayer.frame = CGRect(x: xscale(pt: 0), y: yscale(pt: 1),
      width: xdelta(pt1: Double(neutral), pt2: 0.0), height: yscale(pt: 1))
    negativeLayer.frame = CGRect(x: xscale(pt: 0), y: yscale(pt: 2),
      width: xdelta(pt1: Double(negative), pt2: 0.0), height: yscale(pt: 1))
    
    positiveFace.alpha = 0.0
    negativeFace.alpha = 0.0
    neutralFace.alpha = 0.0
    waitingFace.alpha = 0.0
    
    if positive == 0 && negative == 0 && neutral == 0 {
      waitingFace.alpha = 0.5
    } else if positive == maxValue {
      positiveFace.alpha = 1.0
    } else if negative == maxValue {
      negativeFace.alpha = 1.0
    } else {
      neutralFace.alpha = 1.0
    }
  }
}