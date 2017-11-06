//
//  BCCTopView.m
//  
//
//  Created by 陈修武 on 2017/10/9.
//  Copyright © 2017年 Andy. All rights reserved.
//

#import "BCCTopView.h"
#import "UIImage+BCCAdd.h"

//third open source lib
#import <ReactiveObjC/ReactiveObjC.h>

@interface BCCTopView()
/*! 返回按钮  */
@property (nonatomic, strong) UIButton *backButton;

@property (nonatomic, strong) UIButton *qualityButton;
@property (nonatomic, strong) UIButton *settingsButton;

@property (nonatomic, strong, readwrite) RACSubject *subject;

@end

@implementation BCCTopView

- (void)dealloc {
    NSLog(@"BCCTopView dealloc");
    [self.subject sendCompleted];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize size = self.bounds.size;
    if (CGSizeEqualToSize(size, CGSizeZero)) { return; }
    
    CGFloat orignY = CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
    /** orignY 为状态栏的高度
     *  由于iOS8以后默认横屏后隐藏状态栏，所以要在当前ViewController中
     *  设置 - (BOOL)prefersStatusBarHidden { return NO; } ,否则
     *  orignY 的值为0.
     */
    if (orignY == 0.0f) {
        orignY = 20;
    }
    /*
    self.settingsButton.frame = CGRectMake(size.width - 10 - 30,
                                           orignY,
                                           size.width * 0.5,
                                           size.height - orignY);
    
    self.qualityButton.frame = CGRectMake(self.settingsButton.frame.origin.x - 10 - 30,
                                          orignY,
                                          30,
                                          size.height - 20);
    */
    self.backButton.frame = CGRectMake(10,
                                       orignY,
                                       size.width * 0.5,
                                       size.height - orignY);
    
}

- (void)initialize {
    self.subject = [RACSubject subject];
    
    @weakify(self)
    [[self.backButton rac_signalForControlEvents:UIControlEventTouchUpInside]
     subscribeNext:^(__kindof UIControl * _Nullable x) {
         @strongify(self)
         [self.subject sendNext:@(BCCTopBackButton)];
     }];
    [self addSubview:self.backButton];
    
    /**
    [[self.qualityButton rac_signalForControlEvents:UIControlEventTouchUpInside]
     subscribeNext:^(__kindof UIControl * _Nullable x) {
         @strongify(self)
         [self.subject sendNext:@(BCCTopQualityButton)];
     }];
    [self addSubview:self.qualityButton];

    RAC(self.qualityButton.titleLabel, text) = RACObserve(self, quality);
    
    [[self.settingsButton rac_signalForControlEvents:UIControlEventTouchUpInside]
     subscribeNext:^(__kindof UIControl * _Nullable x) {
         @strongify(self)
         [self.subject sendNext:@(BCCTopSettingButton)];
     }];
    [self addSubview:self.settingsButton];
    */
    [[RACObserve(self, title) skip:1] subscribeNext:^(NSString *title) {
        @strongify(self)
        [self.backButton setTitle:title forState:UIControlStateNormal];
    }];
     
}

#pragma mark - getters setters

- (UIButton *)backButton {
    if (_backButton == nil) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setImage:[UIImage bcc_imageNamed:@"candy_back_btn"] forState:UIControlStateNormal];
        _backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _backButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _backButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
        
    }
    return _backButton;
}

- (UIButton *)qualityButton {
    if (_qualityButton == nil) {
        _qualityButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _qualityButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_qualityButton setTitle:@"高清" forState:UIControlStateNormal];
        [_qualityButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    }
    return _qualityButton;
}

- (UIButton *)settingsButton {
    if (_settingsButton == nil) {
        _settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_settingsButton setImage:[UIImage imageNamed:@"candy_settings_btn"] forState:UIControlStateNormal];
        _settingsButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;

    }
    return _settingsButton;
}



@end
