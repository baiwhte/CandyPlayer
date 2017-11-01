//
//  BCCTopView.m
//  CandyPlayer
//
//  Created by 陈修武 on 2017/9/25.
//  Copyright © 2017年 baiwhte. All rights reserved.
//

#import "BCCTopView.h"

#import <ReactiveObjC/ReactiveObjC.h>

@interface BCCTopView()

/*! 返回按钮 */
@property (nonatomic, strong) UIButton *backButton;

@end

@implementation BCCTopView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
}

- (void)initialize {
    [self addSubview:self.backButton];
}

- (void)initCommand {
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        return [RACSignal return:input];
    }];
    self.backButton.rac_command = command;
}

#pragma mark - properties

- (UIButton *)backButton {
    if (_backButton == nil) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setImage:[UIImage imageNamed:@"coursePlayerPlayBtn"] forState:UIControlStateNormal];
        [_backButton setImage:[UIImage imageNamed:@"coursePlayerPlayBtn"] forState:UIControlStateNormal | UIControlStateHighlighted];
        [_backButton setImage:[UIImage imageNamed:@"coursePlayerSuspendBtn"] forState:UIControlStateSelected];
        [_backButton setImage:[UIImage imageNamed:@"coursePlayerSuspendBtn"] forState:UIControlStateSelected | UIControlStateHighlighted];
        _backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    }
    return _backButton;
}

@end
