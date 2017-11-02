//
//  BCCBrightnessView.h
//
//  Created by baiwhte on 2017/4/10.
//  Copyright © 2017年 baiwhte. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BCCBrightnessView : UIView

@property (nonatomic, assign) UIDeviceOrientation orientation;

+ (instancetype)sharedBrightnessView;

@end
