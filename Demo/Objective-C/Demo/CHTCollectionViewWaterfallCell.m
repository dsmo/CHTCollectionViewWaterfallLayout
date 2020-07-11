//
//  UICollectionViewWaterfallCell.m
//  Demo
//
//  Created by Nelson on 12/11/27.
//  Copyright (c) 2012年 Nelson. All rights reserved.
//

#import "CHTCollectionViewWaterfallCell.h"

@implementation CHTCollectionViewWaterfallCell

#pragma mark - Accessors
- (UIImageView *)imageView {
  if (!_imageView) {
    _imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
    _imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [_imageView.layer setMasksToBounds:YES];
  }
  return _imageView;
}

- (UILabel *)label {
  if (!_label) {
    _label = [[UILabel alloc] init];
    _label.font = [UIFont systemFontOfSize:50.0];
    _label.textColor = UIColor.whiteColor;
  }
  return _label;
}

- (id)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self.contentView addSubview:self.imageView];
    [self.contentView addSubview:self.label];
  }
  return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.label sizeToFit];
    CGRect frame = self.label.frame;
    frame.origin = CGPointMake(round(CGRectGetWidth(self.bounds) - CGRectGetWidth(frame)), round(CGRectGetHeight(self.bounds) - CGRectGetHeight(frame)));
    self.label.frame = frame;
}

@end
