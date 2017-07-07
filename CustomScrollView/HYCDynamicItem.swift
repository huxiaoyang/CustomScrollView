//
//  HYCDynamicItem.swift
//  SwiftCustomScrollView
//
//  Created by ucredit-XiaoYang on 2017/6/28.
//  Copyright © 2017年 XiaoYang. All rights reserved.
//

import Foundation
import UIKit


class HYCDynamicItem: NSObject, UIDynamicItem {
    
    var center: CGPoint = CGPoint.zero
    var transform: CGAffineTransform = CGAffineTransform.identity
    var bounds: CGRect
    
    override init() {
        self.bounds = CGRect(x: 0, y: 0, width: 1, height: 1)
    }
    
}
