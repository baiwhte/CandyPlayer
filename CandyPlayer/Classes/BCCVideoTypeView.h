//
//  BCCVedioTypeView.h
//  YingShengEnterpriseEdition
//
//  Created by 陈修武 on 2017/10/9.
//  Copyright © 2017年 Andy. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BCCPlayItem;

typedef void(^BCCVideoTypeViewBlock)(NSInteger index);

@interface BCCVideoTypeView : UIView

@property (nonatomic, copy) BCCVideoTypeViewBlock block;

- (void)showAnimate;
- (void)reloadItems:(NSArray<BCCPlayItem *> *)items selectedItem:(NSInteger)selectedItem;

@end
