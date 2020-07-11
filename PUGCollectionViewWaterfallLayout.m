//
//  PUGCollectionViewWaterfallLayout.m
//  PUGSwipe
//
//  Created by shiyu on 2020/7/09.
//

#import "PUGCollectionViewWaterfallLayout.h"

static CGFloat PUGCollectionViewWaterfallLayoutFloorCGFloat(CGFloat value) {
    CGFloat scale = [UIScreen mainScreen].scale;
    return floor(value * scale) / scale;
}

static const NSInteger kMaxUnionItemCount = 20;

@interface PUGCollectionViewWaterfallLayout ()

// delegate 指向 self.collectionView.delegate
@property (nonatomic, weak, readonly) id<PUGCollectionViewWaterfallLayoutDelegate> delegate;
// 二维数组，存储每一个排的长度
@property (nonatomic, strong) NSMutableArray<NSMutableArray<NSNumber *> *> *lineLengths;
// 二维数组，每个子数组对应一个 Section 的 item 属性
@property (nonatomic, strong) NSMutableArray<NSMutableArray<UICollectionViewLayoutAttributes *> *> *sectionItemAttributes;
// 一维数组，存储所有 item 的 layout 属性，包括 headers, cells, footers
@property (nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *allItemAttributes;
// 存储 header 属性的字典
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UICollectionViewLayoutAttributes *> *headersAttribute;
// 存储 footer 属性的字典
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UICollectionViewLayoutAttributes *> *footersAttribute;
// unionRect 缓存，用于提高在 -layoutAttributesForElementsInRect: 方法中通过 rect 参数查找 LayoutAttributes 的效率
@property (nonatomic, strong) NSMutableArray<NSValue *> *unionRects;

@end

@implementation PUGCollectionViewWaterfallLayout

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _scrollDirection = UICollectionViewScrollDirectionVertical;
    _numberOfLines = 2;
    _lineSpacing = 10.0;
    _interitemSpacing = 10.0;
    _headerSize = CGSizeZero;
    _footerSize = CGSizeZero;
    _headerInset = UIEdgeInsetsZero;
    _footerInset = UIEdgeInsetsZero;
    _itemRenderMode = PUGCollectionViewWaterfallItemRenderModeShortestFirst;
}

#pragma mark - Public Accessors

- (void)setScrollDirection:(UICollectionViewScrollDirection)scrollDirection {
    if (_scrollDirection != scrollDirection) {
        _scrollDirection = scrollDirection;
        [self invalidateLayout];
    }
}

- (void)setNumberOfLines:(NSInteger)numberOfLines {
    if (_numberOfLines != numberOfLines) {
        _numberOfLines = numberOfLines;
        [self invalidateLayout];
    }
}

- (void)setLineSpacing:(CGFloat)lineSpacing {
    if (_lineSpacing != lineSpacing) {
        _lineSpacing = lineSpacing;
        [self invalidateLayout];
    }
}

- (void)setInteritemSpacing:(CGFloat)interitemSpacing {
    if (_interitemSpacing != interitemSpacing) {
        _interitemSpacing = interitemSpacing;
        [self invalidateLayout];
    }
}

- (void)setHeaderSize:(CGSize)headerSize {
    if (!CGSizeEqualToSize(_headerSize, headerSize)) {
        _headerSize = headerSize;
        [self invalidateLayout];
    }
}

- (void)setFooterSize:(CGSize)footerSize {
    if (!CGSizeEqualToSize(_footerSize, footerSize)) {
        _footerSize = footerSize;
        [self invalidateLayout];
    }
}

- (void)setHeaderInset:(UIEdgeInsets)headerInset {
    if (!UIEdgeInsetsEqualToEdgeInsets(_headerInset, headerInset)) {
        _headerInset = headerInset;
        [self invalidateLayout];
    }
}

- (void)setFooterInset:(UIEdgeInsets)footerInset {
    if (!UIEdgeInsetsEqualToEdgeInsets(_footerInset, footerInset)) {
        _footerInset = footerInset;
        [self invalidateLayout];
    }
}

- (void)setSectionInset:(UIEdgeInsets)sectionInset {
    if (!UIEdgeInsetsEqualToEdgeInsets(_sectionInset, sectionInset)) {
        _sectionInset = sectionInset;
        [self invalidateLayout];
    }
}

- (void)setItemRenderMode:(PUGCollectionViewWaterfallItemRenderMode)itemRenderMode {
    if (_itemRenderMode != itemRenderMode) {
        _itemRenderMode = itemRenderMode;
        [self invalidateLayout];
    }
}

- (void)setItemResizingMode:(PUGCollectionViewWaterfallItemResizingModeMode)itemResizingMode {
    if (_itemResizingMode != itemResizingMode) {
        _itemResizingMode = itemResizingMode;
        [self invalidateLayout];
    }
}

#pragma mark - Private Accessors

- (id<PUGCollectionViewWaterfallLayoutDelegate>)delegate {
    return (id<PUGCollectionViewWaterfallLayoutDelegate>)self.collectionView.delegate;
}

- (NSMutableArray<NSMutableArray<NSNumber *> *> *)lineLengths {
    if (!_lineLengths) {
        _lineLengths = [NSMutableArray array];
    }
    return _lineLengths;
}

- (NSMutableArray<NSMutableArray<UICollectionViewLayoutAttributes *> *> *)sectionItemAttributes {
    if (!_sectionItemAttributes) {
        _sectionItemAttributes = [NSMutableArray array];
    }
    return _sectionItemAttributes;
}

- (NSMutableArray<UICollectionViewLayoutAttributes *> *)allItemAttributes {
    if (!_allItemAttributes) {
        _allItemAttributes = [NSMutableArray array];
    }
    return _allItemAttributes;
}

- (NSMutableDictionary<NSNumber *,UICollectionViewLayoutAttributes *> *)headersAttribute {
    if (!_headersAttribute) {
        _headersAttribute = [NSMutableDictionary dictionary];
    }
    return _headersAttribute;
}

- (NSMutableDictionary<NSNumber *,UICollectionViewLayoutAttributes *> *)footersAttribute {
    if (!_footersAttribute) {
        _footersAttribute = [NSMutableDictionary dictionary];
    }
    return _footersAttribute;
}

- (NSMutableArray<NSValue *> *)unionRects {
    if (!_unionRects) {
        _unionRects = [NSMutableArray array];
    }
    return _unionRects;
}

#pragma mark - Private Methods

- (NSInteger)numberOfLinesInSection:(NSInteger)section {
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionView:layout:numberOfLinesInSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self numberOfLinesInSection:section];
    } else {
        return self.numberOfLines;
    }
}

- (CGFloat)interitemSpacingForSectionAtIndex:(NSInteger)section {
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionView:layout:interitemSpacingForSectionAtIndex:)]) {
        return [self.delegate collectionView:self.collectionView layout:self interitemSpacingForSectionAtIndex:section];
    } else {
        return self.interitemSpacing;
    }
}

- (CGFloat)lineSpacingForSectionAtIndex:(NSInteger)section {
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionView:layout:lineSpacingForSectionAtIndex:)]) {
        return [self.delegate collectionView:self.collectionView layout:self lineSpacingForSectionAtIndex:section];
    } else {
        return self.lineSpacing;
    }
}

- (CGSize)referenceItemSizeAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:refrenceSizeForItemAtIndexPath:)]) {
        return [self.delegate collectionView:self.collectionView layout:self refrenceSizeForItemAtIndexPath:indexPath];
    }
    return CGSizeZero;
}

- (CGSize)referenceSizeForHeaderInSection:(NSInteger)section {
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)]) {
       return [self.delegate collectionView:self.collectionView layout:self referenceSizeForHeaderInSection:section];
   } else {
       return self.headerSize;
   }
}

- (CGSize)referenceSizeForFooterInSection:(NSInteger)section {
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForFooterInSection:)]) {
       return [self.delegate collectionView:self.collectionView layout:self referenceSizeForFooterInSection:section];
   } else {
       return self.footerSize;
   }
}

- (UIEdgeInsets)insetForSectionAtIndex:(NSInteger)section {
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
        return [self.delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:section];
    } else {
        return self.sectionInset;
    }
}

- (UIEdgeInsets)insetForHeaderInSection:(NSInteger)section {
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionView:layout:insetForHeaderInSection:)]) {
       return [self.delegate collectionView:self.collectionView layout:self insetForHeaderInSection:section];
   } else {
       return self.headerInset;
   }
}

- (UIEdgeInsets)insetForFooterInSection:(NSInteger)section {
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionView:layout:insetForFooterInSection:)]) {
       return [self.delegate collectionView:self.collectionView layout:self insetForFooterInSection:section];
   } else {
       return self.footerInset;
   }
}

- (NSUInteger)nextLineIndexForItem:(NSInteger)item inSection:(NSInteger)section {
    NSUInteger index = 0;
    NSInteger lineCount = [self numberOfLinesInSection:section];
    switch (self.itemRenderMode) {
        case PUGCollectionViewWaterfallItemRenderModeShortestFirst:
            index = [self shortestLineIndexInSection:section];
            break;
        case PUGCollectionViewWaterfallItemRenderModeStartToEnd:
            index = (item % lineCount);
            break;
        case PUGCollectionViewWaterfallItemRenderModeEndToStart:
            index = (lineCount - 1) - (item % lineCount);
            break;
        default:
            index = [self shortestLineIndexInSection:section];
            break;
    }
    return index;
}

- (NSUInteger)shortestLineIndexInSection:(NSInteger)section {
    __block NSUInteger index = 0;
    __block CGFloat shortestLength = CGFLOAT_MAX;
    
    [self.lineLengths[section] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat length = [obj doubleValue];
        if (length < shortestLength) {
            shortestLength = length;
            index = idx;
        }
    }];
    
    return index;
}

- (NSUInteger)longestLineIndexInSection:(NSInteger)section {
    __block NSUInteger index = 0;
    __block CGFloat longestLength = 0;
    
    [self.lineLengths[section] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat length = [obj doubleValue];
        if (length > longestLength) {
            longestLength = length;
            index = idx;
        }
    }];
    
    return index;
}

- (CGFloat)lineWidthInSectionAtIndex:(NSInteger)section {
    if (section < 0 || !self.collectionView) {
        return 0;
    }
    
    NSInteger lineCount = [self numberOfLinesInSection:section];
    NSAssert(lineCount > 0, @"PUGCollectionViewWaterfallLayout's numberOfLines should be greater than 0, or delegate must return a value greater than 0 in collectionView:layout:numberOfLinesInSection:");
    CGFloat lineSpacing = [self lineSpacingForSectionAtIndex:section];
    UIEdgeInsets sectionInset = [self insetForSectionAtIndex:section];
    
    CGSize collectionViewSize = self.collectionView.bounds.size;
    CGFloat lineWidth = 0.0;
    
    switch (self.scrollDirection) {
        case UICollectionViewScrollDirectionVertical:
        {
            CGFloat contentWidth = collectionViewSize.width - sectionInset.left - sectionInset.right;
            lineWidth = PUGCollectionViewWaterfallLayoutFloorCGFloat((contentWidth - (lineCount - 1) * lineSpacing) / lineCount);
        }
            break;
        case UICollectionViewScrollDirectionHorizontal:
        {
            CGFloat contentHeight = collectionViewSize.height - sectionInset.top - sectionInset.bottom;
            lineWidth = PUGCollectionViewWaterfallLayoutFloorCGFloat((contentHeight - (lineCount - 1) * lineSpacing) / lineCount);
        }
            break;
        default:
        {
            CGFloat contentWidth = collectionViewSize.width - sectionInset.left - sectionInset.right;
            lineWidth = PUGCollectionViewWaterfallLayoutFloorCGFloat((contentWidth - (lineCount - 1) * lineSpacing) / lineCount);
        }
            break;
    }
    return lineWidth;
}

- (void)prepareLayoutAttributesForVerticalScrollWithNumberOfSections:(NSInteger)numberOfSections {
    if (numberOfSections <= 0) {
        return;
    }
    
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = self.collectionView.safeAreaInsets;
    }
    
    CGFloat collectionViewWidth = CGRectGetWidth(self.collectionView.bounds) - safeAreaInsets.left - safeAreaInsets.right;
    CGFloat top = 0.0;
    // Crate Layout Attributes
    for (NSInteger section = 0; section < numberOfSections; section++) {
        // 1. 获取 lineCount, lineSpacing, interitemSpacing, sectionInset
        NSInteger lineCount = [self numberOfLinesInSection:section];
        NSAssert(lineCount > 0, @"PUGCollectionViewWaterfallLayout's numberOfLines should be greater than 0, or delegate must return a value greater than 0 in collectionView:layout:numberOfLinesInSection:");
        
        CGFloat lineSpacing = [self lineSpacingForSectionAtIndex:section];
        CGFloat interitemSpacing = [self interitemSpacingForSectionAtIndex:section];
        UIEdgeInsets sectionInset = [self insetForSectionAtIndex:section];
        
        // 计算 itemWidth
        CGFloat contentWidth = collectionViewWidth - sectionInset.left - sectionInset.right;
        CGFloat itemWidth = PUGCollectionViewWaterfallLayoutFloorCGFloat((contentWidth - (lineCount - 1) * lineSpacing) / lineCount);
        
        // 2. 创建 Section Header Attribues
        CGFloat headerHeight = [self referenceSizeForHeaderInSection:section].height;
        if (headerHeight > 0) {
            UIEdgeInsets headerInset = [self insetForHeaderInSection:section];
            top += headerInset.top;
            
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
            attributes.frame = CGRectMake(headerInset.left, top, collectionViewWidth - headerInset.left - headerInset.right, headerHeight);
            
            self.headersAttribute[@(section)] = attributes;
            [self.allItemAttributes addObject:attributes];
            
            top = CGRectGetMaxY(attributes.frame) + headerInset.bottom;
        }
        
        // 初始化 self.lineLengths
        top += sectionInset.top;
        for (NSInteger i = 0; i < lineCount; i++) {
            self.lineLengths[section][i] = @(top);
        }
        
        // 3. 创建 Section Item Attribues
        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
        NSMutableArray<UICollectionViewLayoutAttributes *> *itemAttributesArray = [NSMutableArray arrayWithCapacity:itemCount];
        
        for (NSInteger i = 0; i < itemCount; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:section];
            NSUInteger lineIndex = [self nextLineIndexForItem:i inSection:section];
            CGFloat xOffset = sectionInset.left + (itemWidth + lineSpacing) * lineIndex;
            CGFloat yOffset = [self.lineLengths[section][lineIndex] doubleValue];
            CGSize itemSize = [self referenceItemSizeAtIndexPath:indexPath];
            
            CGFloat itemHeight = 0.0;
            switch (self.itemResizingMode) {
                case PUGCollectionViewWaterfallItemResizingModeUseOrignalSize:
                {
                    itemHeight = itemSize.height > 0.0 ? PUGCollectionViewWaterfallLayoutFloorCGFloat(itemSize.height) : 0.0;
                }
                    break;
                case PUGCollectionViewWaterfallItemResizingModeKeepAspectRatio:
                {
                    if (itemSize.height > 0.0 && itemSize.width > 0.0) {
                        itemHeight = PUGCollectionViewWaterfallLayoutFloorCGFloat(itemSize.height / itemSize.width * itemWidth);
                    }
                }
                    break;
                default:
                {
                    itemHeight = itemSize.height > 0.0 ? PUGCollectionViewWaterfallLayoutFloorCGFloat(itemSize.height) : 0.0;
                }
                    break;
            }
            
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            attributes.frame = CGRectMake(xOffset, yOffset, itemWidth, itemHeight);
            
            [itemAttributesArray addObject:attributes];
            [self.allItemAttributes addObject:attributes];
            self.lineLengths[section][lineIndex] = @(CGRectGetMaxY(attributes.frame) + interitemSpacing);
        }
        
        [self.sectionItemAttributes addObject:itemAttributesArray];
        
        // 4. 创建 Section Footer Attribues
        NSUInteger longestLineIndex = [self longestLineIndexInSection:section];
        top = [self.lineLengths[section][longestLineIndex] doubleValue] - interitemSpacing + sectionInset.bottom;
        
        CGFloat footerHeight = [self referenceSizeForFooterInSection:section].height;
        if (footerHeight > 0) {
            UIEdgeInsets footerInset = [self insetForFooterInSection:section];
            top += footerInset.top;
            
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter withIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
            attributes.frame = CGRectMake(footerInset.left, top, collectionViewWidth - footerInset.left - footerInset.right, footerHeight);
            
            self.footersAttribute[@(section)] = attributes;
            [self.allItemAttributes addObject:attributes];
            
            top = CGRectGetMaxY(attributes.frame) + footerInset.bottom;
        }
        
        for (NSInteger i = 0; i < lineCount; i++) {
            self.lineLengths[section][i] = @(top);
        }
    }
}

- (void)prepareLayoutAttributesForHorizontalScrollWithNumberOfSections:(NSInteger)numberOfSections {
    if (numberOfSections <= 0) {
        return;
    }
    
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = self.collectionView.safeAreaInsets;
    }
    
    CGFloat collectionViewHeight = CGRectGetHeight(self.collectionView.bounds) - safeAreaInsets.top - safeAreaInsets.bottom;
    CGFloat left = 0.0;
    // Crate Layout Attributes
    for (NSInteger section = 0; section < numberOfSections; section++) {
        // 1. 获取 lineCount, lineSpacing, interitemSpacing, sectionInset
        NSInteger lineCount = [self numberOfLinesInSection:section];
        NSAssert(lineCount > 0, @"PUGCollectionViewWaterfallLayout's numberOfLines should be greater than 0, or delegate must return a value greater than 0 in collectionView:layout:numberOfLinesInSection:");
        
        CGFloat lineSpacing = [self lineSpacingForSectionAtIndex:section];
        CGFloat interitemSpacing = [self interitemSpacingForSectionAtIndex:section];
        UIEdgeInsets sectionInset = [self insetForSectionAtIndex:section];
        
        // 计算 itemHeight
        CGFloat contentHeight = collectionViewHeight - sectionInset.top - sectionInset.bottom;
        CGFloat itemHeight = PUGCollectionViewWaterfallLayoutFloorCGFloat((contentHeight - (lineCount - 1) * lineSpacing) / lineCount);
        
        // 2. 创建 Section Header Attribues
        CGFloat headerWidth = [self referenceSizeForHeaderInSection:section].width;
        if (headerWidth > 0) {
            UIEdgeInsets headerInset = [self insetForHeaderInSection:section];
            left += headerInset.left;
            
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
            attributes.frame = CGRectMake(left, headerInset.top, headerWidth, collectionViewHeight - headerInset.top - headerInset.bottom);
            
            self.headersAttribute[@(section)] = attributes;
            [self.allItemAttributes addObject:attributes];
            
            left = CGRectGetMaxX(attributes.frame) + headerInset.right;
        }
        
        // 初始化 self.lineLengths
        left += sectionInset.left;
        for (NSInteger i = 0; i < lineCount; i++) {
            self.lineLengths[section][i] = @(left);
        }
        
        // 3. 创建 Section Item Attribues
        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
        NSMutableArray<UICollectionViewLayoutAttributes *> *itemAttributesArray = [NSMutableArray arrayWithCapacity:itemCount];
        
        for (NSInteger i = 0; i < itemCount; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:section];
            NSUInteger lineIndex = [self nextLineIndexForItem:i inSection:section];
            CGFloat xOffset = [self.lineLengths[section][lineIndex] doubleValue];
            CGFloat yOffset = sectionInset.top + (itemHeight + lineSpacing) * lineIndex;
            CGSize itemSize = [self referenceItemSizeAtIndexPath:indexPath];
            
            CGFloat itemWidth = 0.0;
            switch (self.itemResizingMode) {
                case PUGCollectionViewWaterfallItemResizingModeUseOrignalSize:
                {
                    itemWidth = itemSize.width > 0.0 ? PUGCollectionViewWaterfallLayoutFloorCGFloat(itemSize.width) : 0.0;
                }
                    break;
                case PUGCollectionViewWaterfallItemResizingModeKeepAspectRatio:
                {
                    if (itemSize.height > 0.0 && itemSize.width > 0.0) {
                        itemWidth = PUGCollectionViewWaterfallLayoutFloorCGFloat(itemSize.width / itemSize.height * itemHeight);
                    }
                }
                    break;
                default:
                {
                    itemWidth = itemSize.width > 0.0 ? PUGCollectionViewWaterfallLayoutFloorCGFloat(itemSize.width) : 0.0;
                }
                    break;
            }
            
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            attributes.frame = CGRectMake(xOffset, yOffset, itemWidth, itemHeight);
            
            [itemAttributesArray addObject:attributes];
            [self.allItemAttributes addObject:attributes];
            self.lineLengths[section][lineIndex] = @(CGRectGetMaxX(attributes.frame) + interitemSpacing);
        }
        
        [self.sectionItemAttributes addObject:itemAttributesArray];
        
        // 4. 创建 Section Footer Attribues
        NSUInteger longestLineIndex = [self longestLineIndexInSection:section];
        left = [self.lineLengths[section][longestLineIndex] doubleValue] - interitemSpacing + sectionInset.right;
        
        CGFloat footerWidth = [self referenceSizeForFooterInSection:section].width;
        if (footerWidth > 0) {
            UIEdgeInsets footerInset = [self insetForFooterInSection:section];
            left += footerInset.left;
            
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter withIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
            attributes.frame = CGRectMake(left, footerInset.top, footerWidth, collectionViewHeight - footerInset.top - footerInset.bottom);
            
            self.footersAttribute[@(section)] = attributes;
            [self.allItemAttributes addObject:attributes];
            
            left = CGRectGetMaxX(attributes.frame) + footerInset.right;
        }
        
        for (NSInteger i = 0; i < lineCount; i++) {
            self.lineLengths[section][i] = @(left);
        }
    }
}

#pragma mark - Override

- (void)prepareLayout {
    [super prepareLayout];
    
    if (!self.collectionView) {
        return;
    }
    
    [self.lineLengths removeAllObjects];
    [self.sectionItemAttributes removeAllObjects];
    [self.allItemAttributes removeAllObjects];
    [self.headersAttribute removeAllObjects];
    [self.footersAttribute removeAllObjects];
    [self.unionRects removeAllObjects];
    
    NSInteger numberOfSections = self.collectionView.numberOfSections;
    if (numberOfSections <= 0) {
        return;
    }
    
    NSAssert([self.delegate conformsToProtocol:@protocol(PUGCollectionViewWaterfallLayoutDelegate)], @"UICollectionView's delegate should conform to PUGCollectionViewWaterfallLayoutDelegate protocol");
    NSAssert(self.numberOfLines > 0 || [self.delegate respondsToSelector:@selector(collectionView:layout:numberOfLinesInSection:)], @"PUGCollectionViewWaterfallLayout's numberOfLines should be greater than 0, or delegate must implement collectionView:layout:numberOfLinesInSection:");
    
    // Initialize lineLengths
    for (NSInteger section = 0; section < numberOfSections; section++) {
        NSInteger numberOfLines = [self numberOfLinesInSection:section];
        NSMutableArray<NSNumber *> *sectionLineLengths = [[NSMutableArray alloc] initWithCapacity:numberOfLines];
        for (NSInteger line = 0; line < numberOfLines; line++) {
            [sectionLineLengths addObject:@(0)];
        }
        [self.lineLengths addObject:sectionLineLengths];
    }
    
    switch (self.scrollDirection) {
        case UICollectionViewScrollDirectionVertical:
            [self prepareLayoutAttributesForVerticalScrollWithNumberOfSections:numberOfSections];
            break;
        case UICollectionViewScrollDirectionHorizontal:
            [self prepareLayoutAttributesForHorizontalScrollWithNumberOfSections:numberOfSections];
            break;
        default:
            [self prepareLayoutAttributesForVerticalScrollWithNumberOfSections:numberOfSections];
            break;
    }
    
    // 计算 unionRect 缓存 Rect -> LayoutAttributes 的对应关系
    NSInteger index = 0;
    NSInteger itemCount = self.allItemAttributes.count;
    while (index < itemCount) {
        CGRect unionRect = self.allItemAttributes[index].frame;
        
        NSInteger rectEndIndex = MIN(index + kMaxUnionItemCount, itemCount);
        
        for (NSInteger i = index + 1; i < rectEndIndex; i++) {
            unionRect = CGRectUnion(unionRect, self.allItemAttributes[i].frame);
        }
        
        index = rectEndIndex;
        [self.unionRects addObject:@(unionRect)];
    }
}

- (CGSize)collectionViewContentSize {
    NSInteger numberOfSections = [self.collectionView numberOfSections];
    if (numberOfSections <= 0) {
        return CGSizeZero;
    }
    
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = self.collectionView.safeAreaInsets;
    }
    
    CGSize contentSize = self.collectionView.bounds.size;
    
    switch (self.scrollDirection) {
        case UICollectionViewScrollDirectionVertical:
            contentSize.width -= (safeAreaInsets.left + safeAreaInsets.right);
            contentSize.height = [[[self.lineLengths lastObject] firstObject] doubleValue];
            break;
        case UICollectionViewScrollDirectionHorizontal:
            contentSize.width = [[[self.lineLengths lastObject] firstObject] doubleValue];
            contentSize.height -= (safeAreaInsets.top + safeAreaInsets.bottom);
            break;
    }
    
    return contentSize;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section >= [self.sectionItemAttributes count]) {
        return nil;
    }
    
    if (indexPath.item >= [self.sectionItemAttributes[indexPath.section] count]) {
        return nil;
    }
    
    return (self.sectionItemAttributes[indexPath.section])[indexPath.item];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = nil;
    if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        attributes = self.headersAttribute[@(indexPath.section)];
    } else if ([elementKind isEqualToString:UICollectionElementKindSectionFooter]) {
        attributes = self.footersAttribute[@(indexPath.section)];
    }
    return attributes;
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSInteger begin = 0, end = self.allItemAttributes.count;

    NSMutableSet<UICollectionViewLayoutAttributes *> *cellArrributes = [NSMutableSet set];
    NSMutableSet<UICollectionViewLayoutAttributes *> *supplementaryHeaderArrributes = [NSMutableSet set];
    NSMutableSet<UICollectionViewLayoutAttributes *> *supplementaryFooterArrributes = [NSMutableSet set];
    NSMutableSet<UICollectionViewLayoutAttributes *> *decorationViewAttributes = [NSMutableSet set];

    for (NSInteger i = 0; i < self.unionRects.count; i++) {
        if (CGRectIntersectsRect(rect, [self.unionRects[i] CGRectValue])) {
            begin = i * kMaxUnionItemCount;
            break;
        }
    }

    for (NSInteger i = self.unionRects.count - 1; i >= 0; i--) {
        if (CGRectIntersectsRect(rect, [self.unionRects[i] CGRectValue])) {
            end = MIN((i + 1) * kMaxUnionItemCount, self.allItemAttributes.count);
            break;
        }
    }

    for (NSInteger i = begin; i < end; i++) {
        UICollectionViewLayoutAttributes *attributes = self.allItemAttributes[i];
        if (CGRectIntersectsRect(rect, attributes.frame)) {
            switch (attributes.representedElementCategory) {
                case UICollectionElementCategorySupplementaryView:
                    if ([attributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
                        [supplementaryHeaderArrributes addObject:attributes];
                    } else if ([attributes.representedElementKind isEqualToString:UICollectionElementKindSectionFooter]) {
                        [supplementaryFooterArrributes addObject:attributes];
                    }
                    break;
                case UICollectionElementCategoryCell:
                    [cellArrributes addObject:attributes];
                    break;
                case UICollectionElementCategoryDecorationView:
                    [decorationViewAttributes addObject:attributes];
                    break;
                default:
                    break;
            }
        }
    }

    NSMutableArray<UICollectionViewLayoutAttributes *> *result = [cellArrributes.allObjects mutableCopy];
    [result addObjectsFromArray:supplementaryHeaderArrributes.allObjects];
    [result addObjectsFromArray:supplementaryFooterArrributes.allObjects];
    [result addObjectsFromArray:decorationViewAttributes.allObjects];
    return result;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    CGRect oldBounds = self.collectionView.bounds;
    if (CGRectGetWidth(newBounds) != CGRectGetWidth(oldBounds)) {
        return YES;
    }
    return NO;
}

@end
