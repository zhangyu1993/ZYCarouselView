# ZYCarouselView
use：
let carouselView = ZYCarouselView()
carouselView.delegate = self
carouselView.dataSource = self

require delegate:
/// item的数量
func numberOfItems(in carouselView: ZYCarouselView) -> Int
/// 自定义的view
func carouselView(_ carouselView: ZYCarouselView, ViewForitemAtIndex index: Int) -> UIView
/// item的大小
func sizeForItem(in carouselView: ZYCarouselView) -> CGSize

optional delegate:
/// 选中的下标
@objc optional func carouselView(_ carouselView: ZYCarouselView, didSelectItemAt index: Int)
 /// 结束滚动时的下标
@objc optional func carouselView(_ carouselView: ZYCarouselView, didEndScrolling index: Int)
