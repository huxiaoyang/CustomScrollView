//
//  CustomScrollView.swift
//  SwiftCustomScrollView
//
//  Created by ucredit-XiaoYang on 2017/6/28.
//  Copyright © 2017年 XiaoYang. All rights reserved.
//
//  Source Blog:https://github.com/fastred/CustomScrollView


import UIKit

class CustomScrollView: UIView {

    public var contentSize: CGSize = .zero
    
    
    private var startBounds: CGRect = .zero
    private var animator: UIDynamicAnimator?
    private weak var decelerationBehavior: UIDynamicItemBehavior?
    private weak var springBehavior: UIAttachmentBehavior?
    private var dynamicItem: HYCDynamicItem?
    fileprivate var lastPointInBounds: CGPoint = .zero
    
    
    
    var tableView: UITableView!
    private var startY: CGFloat = 0.0
    private var endY: CGFloat = 0.0
    
    
    
    override var bounds: CGRect {
        didSet {
            doSetBounds(bounds)
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInitForCustomScrollView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 初始化view
    private func commonInitForCustomScrollView() {
        let panGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(handlePanGesture(_:)))
        self.addGestureRecognizer(panGestureRecognizer)
        
        self.animator = UIDynamicAnimator.init(referenceView: self)
        self.dynamicItem = HYCDynamicItem.init()
        
        
        self.tableView = UITableView(frame: CGRect(x: 0, y: 150, width: self.frame.width, height: self.frame.height), style: .plain)
        self.tableView.rowHeight = 44
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.isScrollEnabled = false
        self.tableView.tableFooterView = UIView()
        self.addSubview(self.tableView)
        self.bringSubview(toFront: self.tableView)
        
    }
    
    // 手势监听
    func handlePanGesture(_ panGestureRecognizer: UIPanGestureRecognizer) {
        
        let maxBoundsOriginYToSelf = self.contentSize.height - self.frame.height
        
        switch panGestureRecognizer.state {
        case .began:
            
            if Int(self.tableView.contentOffset.y) == 0 && self.bounds.minY < maxBoundsOriginYToSelf {
                self.startY = self.bounds.minY
            } else {
                self.startY = self.tableView.contentOffset.y + maxBoundsOriginYToSelf
            }
            
            self.animator?.removeAllBehaviors()
            self.endY = 0.0
            
        case .changed:
            var translation = panGestureRecognizer.translation(in: self)
            let Y = self.startY
            
            if !scrollHorizontal() {
                translation.x = 0.0
            }
            
            if !scrollVertical() {
                translation.y = 0.0
            }
            
            
            // 手势偏移量
            let newBoundsOriginY = Y - translation.y
            // self的最小偏移量
            let minBoundsOriginY: CGFloat = 0.0
            // self最大偏移量
            let maxBoundsOriginY = maxBoundsOriginYToSelf
            // 内部tableView的contentOffset的最大偏移量
            let childMaxBoundsOriginY = self.tableView.contentSize.height - self.frame.height
            // 实际内容最大偏移量
            let contentMaxBoundsOriginY = maxBoundsOriginY + childMaxBoundsOriginY
            // 除去弹簧效果的实际内容偏移量
            let constrainedBoundsOriginY = fmax(minBoundsOriginY, fmin(newBoundsOriginY, contentMaxBoundsOriginY))
            // 弹簧效果偏移量
            let rubberBandedY = rubberBandDistance(offset: newBoundsOriginY - constrainedBoundsOriginY, dimension: self.bounds.height)
            
            
//            print("newY is \(newBoundsOriginY) \n constrainedBoundsOriginY is \(constrainedBoundsOriginY) \n rubberBandedY is \(rubberBandedY) \n tableView offset is \(self.tableView.contentOffset.y) \n ... \n")
            
            self.bounds.origin.y = fmin(maxBoundsOriginYToSelf, constrainedBoundsOriginY) + rubberBandedY
            
            self.tableView.contentOffset.y = fmin(childMaxBoundsOriginY, fmax(0, newBoundsOriginY - maxBoundsOriginYToSelf))
            
            
        case .ended:
            var velocity = panGestureRecognizer.velocity(in: self)
            velocity.x = -velocity.x
            velocity.y = -velocity.y
            
            if !scrollHorizontal() || outsideBoundsMinimum() || outsideBoundsMaximum() {
                velocity.x = 0
            }
            
            if !scrollVertical() || outsideBoundsMinimum() || outsideBoundsMaximum() {
                velocity.y = 0
            }
            
            if scrollVertical() && fabs(velocity.y) < 5 && fabs(velocity.y) > 0 {
                return
            }
            
            if scrollHorizontal() && fabs(velocity.x) < 5 && fabs(velocity.x) > 0 {
                return
            }
            
            guard let dynamicItem = self.dynamicItem  else {
                return
            }
            
            if Int(self.tableView.contentOffset.y) == 0 && self.bounds.minY < maxBoundsOriginYToSelf {
               
                dynamicItem.center.y = self.bounds.origin.y

            } else {
                
                dynamicItem.center.y = self.tableView.contentOffset.y + maxBoundsOriginYToSelf

            }
            
            
            let decelerationBehavior = UIDynamicItemBehavior.init(items: [dynamicItem])
            decelerationBehavior.addLinearVelocity(velocity, for: dynamicItem)
            decelerationBehavior.resistance = 2.0
            
            decelerationBehavior.action = { [weak self] in
                
                 print("dynamicItem is \(dynamicItem.center.y) \n contentOffset is \(self!.tableView.contentOffset.y) \n newY is \(self!.bounds.origin.y) \n ... \n")
                
                self?.bounds.origin.y = fmax((dynamicItem.center.y - (self!.tableView.contentSize.height - self!.frame.height)), fmin(maxBoundsOriginYToSelf, dynamicItem.center.y))
                
                if self!.tableView.contentOffset.y == (self!.tableView.contentSize.height - self!.frame.height) {
                    self!.endY = self!.tableView.contentSize.height - self!.frame.height
                }
                
                if self!.endY > 0 {
                    self?.tableView.contentOffset.y = self!.endY
                } else {
                    self?.tableView.contentOffset.y = fmin(self!.tableView.contentSize.height - self!.frame.height, fmax(0, dynamicItem.center.y - maxBoundsOriginYToSelf))
                }
                
            }
            
            guard let animator = self.animator  else {
                return
            }
            animator.addBehavior(decelerationBehavior)
            self.decelerationBehavior = decelerationBehavior
            
        default:
            break
        }
        
        
    }
    
    
    private func doSetBounds(_ bounds: CGRect) {
        if (outsideBoundsMinimum() || outsideBoundsMaximum()) &&
            ((self.decelerationBehavior != nil) && (self.springBehavior == nil)) {
            
            let target = self.anchar()
            
            guard let dynamicItem = self.dynamicItem else {
                return
            }
            let springBehavior = UIAttachmentBehavior.init(item: dynamicItem, attachedToAnchor: target)
            springBehavior.length = 0
            springBehavior.damping = 1
            springBehavior.frequency = 2
            
            guard let animator = self.animator else {
                return
            }
            animator.addBehavior(springBehavior)
            self.springBehavior = springBehavior
        }
    }
    
    
    
}


extension CustomScrollView {
    
    // 弹簧效果
    fileprivate func rubberBandDistance(offset: CGFloat, dimension: CGFloat) -> CGFloat {
        let constant: CGFloat = 0.55
        let result = (constant * fabs(offset) * dimension) / (dimension + constant * fabs(offset))
        
        return offset < 0.0 ? -result : result
    }
    
    // 是否垂直滑动
    fileprivate func scrollVertical() -> Bool {
        return self.contentSize.height > self.bounds.height
    }
    
    // 是否水平滑动
    fileprivate func scrollHorizontal() -> Bool {
        return self.contentSize.width > self.bounds.width
    }
    
    // 向下或向左滑动触发branch
    fileprivate func outsideBoundsMinimum() -> Bool {
        return self.bounds.origin.x < 0.0 || self.bounds.origin.y < 0.0
    }
    
    // 向上或向右滑动触发branch
    fileprivate func outsideBoundsMaximum() -> Bool {
        let maxBoundsOrigin = self.maxBoundsOrigin()
        return self.bounds.origin.x > maxBoundsOrigin.x || self.bounds.origin.y > maxBoundsOrigin.y
    }
    
    // 最大边界，右下角
    fileprivate func maxBoundsOrigin() -> CGPoint {
        return CGPoint(x: self.contentSize.width - self.bounds.size.width,
                       y: self.contentSize.height - self.bounds.size.height)
    }
    
    // 锚点
    fileprivate func anchar() -> CGPoint {
        let cBounds = self.bounds
        let maxBoundsOrigin = self.maxBoundsOrigin()
        
        let deltaX = self.lastPointInBounds.x - cBounds.origin.x
        let deltaY = self.lastPointInBounds.y - cBounds.origin.y
        
        let a = deltaY / deltaX
        let b = self.lastPointInBounds.y - self.lastPointInBounds.x * a
        
        let leftBending = -cBounds.origin.x
        let topBending = -cBounds.origin.y
        let rightBending = cBounds.origin.x - self.maxBoundsOrigin().x
        let bottomBending = cBounds.origin.y - self.maxBoundsOrigin().y
        
        func solveForY(_ anchor: inout CGPoint) -> Void {
            if deltaY != 0 {
                anchor.y = a * anchor.x + b
            }
        }
        
        func solveForX(_ anchar: inout CGPoint) -> Void {
            if deltaX != 0 {
                anchar.x = (anchar.y - b) / a
            }
        }
        
        
        var anchar = cBounds.origin
        
        if cBounds.origin.x < 0.0 && leftBending > topBending && leftBending > bottomBending {
            anchar.x = 0
            solveForY(&anchar)
        }
        else if cBounds.origin.y < 0.0 && topBending > leftBending && topBending > rightBending {
            anchar.y = 0.0
            solveForX(&anchar)
        }
        else if cBounds.origin.x > self.maxBoundsOrigin().x && rightBending > topBending && rightBending > bottomBending {
            anchar.x = self.maxBoundsOrigin().x
            solveForY(&anchar)
        }
        else if cBounds.origin.y > self.maxBoundsOrigin().y {
            anchar.y = self.maxBoundsOrigin().y
            solveForX(&anchar)
        }
        
        return anchar
    }

    
}



extension CustomScrollView: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: "cell")
        }
        
        cell?.textLabel?.text = "cell row is \(indexPath.row)"
        cell?.backgroundColor = indexPath.row % 2 == 0 ? UIColor.green : UIColor.orange
        
        return cell!
    }
    
}



