//
//  BCCTopView.h
//  CandyPlayer
//
//  Created by 陈修武 on 2017/9/25.
//  Copyright © 2017年 baiwhte. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RACCommand;

@interface BCCTopView : UIView

@property (nonatomic, strong, readonly) RACCommand *backCommand;

@end
