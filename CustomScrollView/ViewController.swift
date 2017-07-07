//
//  ViewController.swift
//  CustomScrollView
//
//  Created by ucredit-XiaoYang on 2017/7/5.
//  Copyright © 2017年 XiaoYang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scrollView = CustomScrollView(frame: CGRect.init(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        scrollView.backgroundColor = .brown
        scrollView.contentSize = CGSize(width: self.view.bounds.width, height: view.bounds.height + 150)
        
        view.addSubview(scrollView)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }


}

