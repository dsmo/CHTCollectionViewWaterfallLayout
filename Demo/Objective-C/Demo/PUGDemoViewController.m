//
//  PUGDemoViewController.m
//  Demo
//
//  Created by shiyu on 2020/7/11.
//  Copyright © 2020 Nelson. All rights reserved.
//

#import "PUGDemoViewController.h"
#import "CHTCollectionViewWaterfallCell.h"
#import "CHTCollectionViewWaterfallHeader.h"
#import "CHTCollectionViewWaterfallFooter.h"
#import "PUGCollectionViewWaterfallLayout.h"

#define CELL_COUNT 30
#define CELL_IDENTIFIER @"WaterfallCell"
#define HEADER_IDENTIFIER @"WaterfallHeader"
#define FOOTER_IDENTIFIER @"WaterfallFooter"

@interface PUGDemoViewController () <PUGCollectionViewWaterfallLayoutDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *cellSizes;
@property (nonatomic, strong) NSArray *cats;

@end

@implementation PUGDemoViewController

#pragma mark - Accessors

- (NSArray *)cellSizes {
    if (!_cellSizes) {
        _cellSizes = @[
            [NSValue valueWithCGSize:CGSizeMake(550, 550)],
            [NSValue valueWithCGSize:CGSizeMake(1000, 665)],
            [NSValue valueWithCGSize:CGSizeMake(1024, 689)],
            [NSValue valueWithCGSize:CGSizeMake(640, 427)]
        ];
    }
    return _cellSizes;
}

- (NSArray *)cats {
    if (!_cats) {
        _cats = @[@"cat1.jpg", @"cat2.jpg", @"cat3.jpg", @"cat4.jpg"];
    }
    return _cats;
}

#pragma mark - Life Cycle
    
- (void)viewDidLoad {
    [super viewDidLoad];
    PUGCollectionViewWaterfallLayout *layout = (PUGCollectionViewWaterfallLayout *)self.collectionView.collectionViewLayout;
    
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.sectionInset = UIEdgeInsetsMake(1.0, 1.0, 1.0, 1.0);
    layout.headerSize = CGSizeMake(50.0, 50.0);
    layout.footerSize = CGSizeMake(50.0, 50.0);
    layout.headerInset = UIEdgeInsetsMake(1.0, 1.0, 1.0, 1.0);
    layout.footerInset = UIEdgeInsetsMake(1.0, 1.0, 1.0, 1.0);
    layout.lineSpacing = 2.0;
    layout.interitemSpacing = 2.0;
    layout.itemRenderMode = PUGCollectionViewWaterfallItemRenderModeStartToEnd;
    layout.itemResizingMode = PUGCollectionViewWaterfallItemResizingModeKeepAspectRatio;
    
    [self.collectionView registerClass:[CHTCollectionViewWaterfallCell class]
    forCellWithReuseIdentifier:CELL_IDENTIFIER];
    [self.collectionView registerClass:[CHTCollectionViewWaterfallHeader class]
    forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
           withReuseIdentifier:HEADER_IDENTIFIER];
    [self.collectionView registerClass:[CHTCollectionViewWaterfallFooter class]
    forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
           withReuseIdentifier:FOOTER_IDENTIFIER];
    
    if (@available(iOS 11.0, *)) {
        self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    }
    
    [self updateLayoutSizeClasss:self.traitCollection];
}

- (void)updateLayoutSizeClasss:(UIUserInterfaceSizeClass)sizeClass {
    PUGCollectionViewWaterfallLayout *layout =
    (PUGCollectionViewWaterfallLayout *)self.collectionView.collectionViewLayout;
    layout.numberOfLines = sizeClass == UIUserInterfaceSizeClassCompact ? 2 : 5;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    PUGCollectionViewWaterfallLayout *layout = (PUGCollectionViewWaterfallLayout *)self.collectionView.collectionViewLayout;
    
    UIUserInterfaceSizeClass sizeClassForLayout;
    switch (layout.scrollDirection) {
        case UICollectionViewScrollDirectionVertical:
        {
            sizeClassForLayout = self.traitCollection.horizontalSizeClass;
        }
            break;
        case UICollectionViewScrollDirectionHorizontal:
        default:
        {
            sizeClassForLayout = self.traitCollection.verticalSizeClass;
        }
            break;
    }
    
    [self updateLayoutSizeClasss:sizeClassForLayout];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return CELL_COUNT;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CHTCollectionViewWaterfallCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CELL_IDENTIFIER forIndexPath:indexPath];
    cell.imageView.image = [UIImage imageNamed:self.cats[indexPath.item % self.cats.count]];
    cell.label.text = [NSString stringWithFormat:@"[%ld, %ld]", (long)indexPath.section, (long)indexPath.item];
    [cell setNeedsLayout];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableView = nil;

    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                          withReuseIdentifier:HEADER_IDENTIFIER
                                                                 forIndexPath:indexPath];
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                          withReuseIdentifier:FOOTER_IDENTIFIER
                                                                 forIndexPath:indexPath];
    }
    
    return reusableView;
}

#pragma mark - PUGCollectionViewDelegateWaterfallLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout refrenceSizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = [self.cellSizes[indexPath.item % self.cats.count] CGSizeValue];
    return size;
}

@end
