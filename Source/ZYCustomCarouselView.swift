//
//  ZYCustomCarouselView.swift
//  TestCollectView
//
//  Created by zhangyu on 2018/9/6.
//  Copyright © 2018年 zhangyu. All rights reserved.
//

import UIKit

@objc protocol ZYCustomCarouselViewDelegate: AnyObject {
    /// 选中的下标
    @objc optional func carouselView(_ carouselView: ZYCustomCarouselView, didSelectItemAt index: Int)
    /// 结束滚动时的下标
    @objc optional func carouselView(_ carouselView: ZYCustomCarouselView, didEndScrolling index: Int)
}

protocol ZYCustomCarouselViewDataSource: AnyObject {
    /// item的数量
    func numberOfItems(in carouselView: ZYCustomCarouselView) -> Int
    /// 自定义的view
    func carouselView(_ carouselView: ZYCustomCarouselView, ViewForitemAtIndex index: Int) -> UIView
    /// item的大小
    func sizeForItem(in carouselView: ZYCustomCarouselView) -> CGSize
}

class ZYCustomCarouselView: UIView, UIScrollViewDelegate {
    /// 逻辑代理
    weak var delegate: ZYCustomCarouselViewDelegate?
    /// 数据源代理
    weak var dataSource: ZYCustomCarouselViewDataSource?
    /// 当前显示的view的下标
    var currentIndex: Int = 0
    /// 外界传入view的size
    var itemSize: CGSize = .zero
    /// 放外界传入的view的contentview numOfItems==1时只有一个 numOfItems>1时固定为5个
    var itemViews: [UIView] = []
    /// 数据源的个数
    var numOfItems: Int = 0
    /// 最大比例
    var minScale: CGFloat = 0.95
    /// 最小比例
    var maxScale: CGFloat = 1
    /// 定时器，用于自动滚动
    private var timer: Timer?
    /// 自动滚动时间间隔
    var scrollTnterval: TimeInterval = 5
    /// 滑动的内容视图
    lazy var contentScrollView: UIScrollView = {
        let s = UIScrollView(frame: .zero)
        s.backgroundColor = .white
        s.isPagingEnabled = true
        s.clipsToBounds = false
        s.delegate = self
        s.showsHorizontalScrollIndicator = false
        self.addSubview(s)
        return s
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    /// 添加定时器
    func addTimer() {
        if timer == nil {
            timer = Timer.init(timeInterval: scrollTnterval, target: self, selector: #selector(run), userInfo: nil, repeats: true)
            RunLoop.main.add(timer!, forMode: RunLoopMode.commonModes)
        }
    }
    
    /// 刷新数据
    func reloadItems() {
        contentScrollView.subviews.forEach( { $0.removeFromSuperview() } )
        if let itemCount = dataSource?.numberOfItems(in: self), let itemSize = dataSource?.sizeForItem(in: self) {
            numOfItems = itemCount
            self.itemSize = itemSize
            setItemData()
        }
    }
    
    /// 设置数据
    func setItemData() {
        contentScrollView.frame = CGRect(x: (self.bounds.width - itemSize.width) / 2, y: 0, width: itemSize.width, height: itemSize.height)
        if numOfItems == 0 {
            timer?.fireDate = .distantFuture
            return
        }
        else if numOfItems == 1 { /// 如果外界传入的数据只有一个，则不用创建5个内容视图
            timer?.fireDate = .distantFuture
            contentScrollView.contentSize = CGSize(width: itemSize.width, height: itemSize.height)
            contentScrollView.isScrollEnabled = false
            let itemView = dataSource?.carouselView(self, ViewForitemAtIndex: currentIndex)
            itemView?.frame = CGRect(x: 0 , y: 0, width: itemSize.width, height: itemSize.height)
            if let _ = itemView {
                contentScrollView.addSubview(itemView!)
            }
        }
        else {
            addTimer()
            timer?.fireDate = Date.init(timeInterval: scrollTnterval, since: Date())
            contentScrollView.contentSize = CGSize(width: itemSize.width * 5, height: itemSize.height)
            contentScrollView.isScrollEnabled = true
            addSubViewToItemContentView()
        }
    }
    
    /// 将要触摸到scrollView 时，关闭用户交互，停止定时器
    ///
    /// - Parameter scrollView: <#scrollView description#>
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        timer?.fireDate = .distantFuture
        scrollView.isUserInteractionEnabled = false
    }
    
    /// 已经结束触摸时 开启定时器
    ///
    /// - Parameters:
    ///   - scrollView: <#scrollView description#>
    ///   - decelerate: <#decelerate description#>
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        timer?.fireDate = Date.init(timeInterval: scrollTnterval, since: Date())
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffset = CGPoint(x: itemSize.width * 2, y: 0)
        let space = scrollView.contentOffset.x - currentOffset.x
        let spaceSacleUp = (maxScale - minScale) * (abs(space) / itemSize.width) + minScale
        let spaceSacleDown = maxScale - (maxScale - minScale) * (abs(space) / itemSize.width)
        if space > 0 {
            if itemViews.count == 5 {
                itemViews[2].transform = CGAffineTransform.init(scaleX: spaceSacleDown, y: spaceSacleDown)
                itemViews[3].transform = CGAffineTransform.init(scaleX: spaceSacleUp, y: spaceSacleUp)
            }
        }
        else {
            if itemViews.count == 5 {
                itemViews[1].transform = CGAffineTransform.init(scaleX: spaceSacleUp, y: spaceSacleUp)
                itemViews[2].transform = CGAffineTransform.init(scaleX: spaceSacleDown, y: spaceSacleDown)
            }
        }
    }
    
    /// 已经结束滚动动画 这时候开放用户交互
    /// 调用setContentOffset方法，结束时会调用此方法
    /// - Parameter scrollView: <#scrollView description#>
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        contentScrollView.isUserInteractionEnabled = true
        scrollViewDidEndDecelerating(scrollView)
    }
    
    /// 已经结束减速  这时候开放用户交互
    ///
    /// - Parameter scrollView: <#scrollView description#>
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollView.isUserInteractionEnabled = true
        let idxDif = Int(scrollView.contentOffset.x / itemSize.width) - 2
        currentIndex = currentIndex + idxDif
        if currentIndex < 0 {
            currentIndex = numOfItems - 1
        }
        if currentIndex > numOfItems - 1 {
            currentIndex = 0
        }
        addSubViewToItemContentView()
        delegate?.carouselView?(self, didEndScrolling: currentIndex)
    }
    
    /// 自动滚动到下一个视图，关闭scrollview的交互是防止滚动时用户交互影响效果，滚动结束时开放用户交互
    func scrollToNext() {
        contentScrollView.isUserInteractionEnabled = false
        contentScrollView.setContentOffset(CGPoint(x: itemSize.width * 3, y: 0), animated: true)
    }

    /// 给5个内容视图添加子视图
    func addSubViewToItemContentView() {
        for i in -2 ... 2 {
            var realIndex = 0
            if currentIndex + i < 0 {
                realIndex = currentIndex + i + numOfItems
            }
            else if currentIndex + i > numOfItems - 1 {
                realIndex = currentIndex + i - numOfItems
            }
            else {
                realIndex = currentIndex + i
            }
            if let subView = dataSource?.carouselView(self, ViewForitemAtIndex: realIndex), realIndex >= 0 && realIndex < numOfItems {
                subView.frame = CGRect(x: 0, y: 0, width: itemSize.width, height: itemSize.height)
                getContenViewOfIndex(index: i + 2).addSubview(subView)
            }
        }
        contentScrollView.contentOffset = CGPoint(x: 2 * itemSize.width, y: 0)
    }
    
    /// 根据下标获取内容视图
    ///
    /// - Parameter index: <#index description#>
    /// - Returns: <#return value description#>
    func getContenViewOfIndex(index: Int) -> UIView {
        var itemView: UIView = UIView()
        if itemViews.count == 5 {
            itemView = itemViews[index]
        }
        else {
            itemView.tag = index + 1
            itemView.frame = CGRect(x: itemSize.width * CGFloat(index), y: 0, width: itemSize.width, height: itemSize.height)
            let tap = UITapGestureRecognizer(target: self, action: #selector(itemTapClick))
            itemView.addGestureRecognizer(tap)
            contentScrollView.addSubview(itemView)
            itemViews.append(itemView)
        }
        itemView.clipsToBounds = true
        itemView.subviews.forEach( { $0.removeFromSuperview() } )
        itemViews[index].transform = index == 2 ? CGAffineTransform.identity : CGAffineTransform.init(scaleX: minScale, y: minScale)
        return itemView
    }
 
    @objc func itemTapClick(tap: UITapGestureRecognizer) {
        if let tapView = tap.view {
            if tapView.tag == 3 {
                delegate?.carouselView?(self, didSelectItemAt: currentIndex)
            }
        }
    }
    
    /// 定时器循环调用方法
    @objc func run() {
        if numOfItems > 1 {
            scrollToNext()
        }
    }
    
    /// 从父视图移除时移除timer
    override func removeFromSuperview() {
        super.removeFromSuperview()
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
