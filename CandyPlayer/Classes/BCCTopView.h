//
//  BCCTopView.h
//
//
//  Created by 陈修武 on 2017/10/9.
//  Copyright © 2017年 Andy. All rights reserved.
//

#import "BCCBaseView.h"

@class RACSubject;

typedef NS_ENUM(NSInteger, BCCTopButtonType) {
    BCCTopBackButton = 1,
    BCCTopQualityButton,
    BCCTopSettingButton
};

@interface BCCTopView : BCCBaseView

@property (nonatomic, copy) NSString *title;

//@property (nonatomic, assign, readonly) BOOL canGoBack;

//@property (nonatomic, assign) BOOL hideQuality;
//@property (nonatomic, copy) NSString *quality;

@property (nonatomic, strong, readonly) RACSubject *subject;

@end
