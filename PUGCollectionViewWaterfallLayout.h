//
//  PUGCollectionViewWaterfallLayout.h
//  PUGSwipe
//
//  Created by shiyu on 2020/7/09.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, PUGCollectionViewWaterfallItemRenderMode) {
    /// 优先填充最短一行
    PUGCollectionViewWaterfallItemRenderModeShortestFirst,
    /// 填充方向从左到右（纵向布局）从上到下（横向布局）
    PUGCollectionViewWaterfallItemRenderModeStartToEnd,
    /// 填充方向从右到左（纵向布局）从下到上（横向布局）
    PUGCollectionViewWaterfallItemRenderModeEndToStart
};

typedef NS_ENUM(NSUInteger, PUGCollectionViewWaterfallItemResizingModeMode) {
    /// 布局时直接使用 itemSize 的宽高
    PUGCollectionViewWaterfallItemResizingModeUseOrignalSize,
    /// 布局时保持 itemSize 宽高比进行缩放
    PUGCollectionViewWaterfallItemResizingModeKeepAspectRatio,
};

@protocol PUGCollectionViewWaterfallLayoutDelegate <UICollectionViewDelegate>

@required
/// Cell 大小，只有对应滑动方向的（纵向 size.height，横向 size.width）被使用
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout refrenceSizeForItemAtIndexPath:(NSIndexPath *)indexPath;

@optional
/// 当前 Setion 的排数
- (NSInteger)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout numberOfLinesInSection:(NSInteger)section;

/// 当前 Section 的 Header 大小，只有对应滑动方向的（纵向 size.height，很像 size.width）被使用
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section;

/// 当前 Section 的 Footer 大小
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section;

/// 当前 Section 的 Inset
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section;

/// 当前 Section 的 Header Inset
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForHeaderInSection:(NSInteger)section;

/// 当前 Section 的 Footer Inset
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForFooterInSection:(NSInteger)section;

/// 当前 Section 的每排间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout lineSpacingForSectionAtIndex:(NSInteger)section;

/// 当前 Section 的每排里的 Cell 间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout interitemSpacingForSectionAtIndex:(NSInteger)section;

@end

/// 可纵向横向布局的瀑布流 CollectionViewLayout
/// 在 PUGCollectionViewWaterfallLayout 中，一排定义纵向布局时的一列，横向布局的一行
IB_DESIGNABLE
@interface PUGCollectionViewWaterfallLayout : UICollectionViewLayout

/// 瀑布流布局方向，默认为 UICollectionViewScrollDirectionVertical 纵向布局
@property (nonatomic, assign) UICollectionViewScrollDirection scrollDirection;
/// 排数，默认 2
@property (nonatomic, assign) IBInspectable NSInteger numberOfLines;
/// 排间距，默认 10
@property (nonatomic, assign) IBInspectable CGFloat lineSpacing;
/// Item 间距，默认 10
@property (nonatomic, assign) IBInspectable CGFloat interitemSpacing;
/// Header Size，默认 CGSizeZero，纵向布局时，只有 size.height 会生效，横向布局时，只有 size.width 会生效
@property (nonatomic, assign) IBInspectable CGSize headerSize;
/// Footer Size，默认 CGSizeZero，纵向布局时，只有 size.height 会生效，横向布局时，只有 size.width 会生效
@property (nonatomic, assign) IBInspectable CGSize footerSize;
/// Header Inset，默认 UIEdgeInsetsZero
@property (nonatomic, assign) IBInspectable UIEdgeInsets headerInset;
/// Footer Inset，默认 UIEdgeInsetsZero
@property (nonatomic, assign) IBInspectable UIEdgeInsets footerInset;
/// Section Inset，默认 UIEdgeInsetsZero
@property (nonatomic, assign) IBInspectable UIEdgeInsets sectionInset;
/// Cell 布局模式，默认 PUGCollectionViewWaterfallItemRenderModeShortestFirst
@property (nonatomic, assign) PUGCollectionViewWaterfallItemRenderMode itemRenderMode;
/// Cell Size 计算模式，默认 PUGCollectionViewWaterfallItemResizingModeUseOrignalSize
@property (nonatomic, assign) PUGCollectionViewWaterfallItemResizingModeMode itemResizingMode;

/// 计算 Section 中一排的宽度
- (CGFloat)lineWidthInSectionAtIndex:(NSInteger)section;

@end

NS_ASSUME_NONNULL_END
