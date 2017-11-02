//
//  BCCVedioTypeView.m
//  
//
//  Created by 陈修武 on 2017/10/9.
//  Copyright © 2017年 Andy. All rights reserved.
//

#import "BCCVideoTypeView.h"
#import "BCCPlayerItem.h"

@interface BCCVideoTypeView()<UITableViewDelegate,UITableViewDataSource, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *tableContentView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<BCCPlayerItem *> *videos;

@end

@implementation BCCVideoTypeView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
        
        [self.tableContentView addSubview:self.tableView];
        [self addSubview:self.tableContentView];
    
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]  initWithTarget:self action:@selector(onTap:)];
        tap.delegate = self;
        tap.numberOfTapsRequired = 1;
        tap.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:tap];
    }
    
    return self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint p = [touch locationInView:self];
    if (CGRectContainsPoint(self.tableContentView.frame, p)) {
        return NO;
    }
    return YES;
}

- (void)onTap:(UITapGestureRecognizer *)ges {
    [self removeAnimate];
}

- (void)reloadItems:(NSArray<BCCPlayerItem *> *)items selectedItem:(NSInteger)selectedItem {
    self.videos = items;
    [self.tableView reloadData];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedItem inSection:0]
                                animated:NO
                          scrollPosition:UITableViewScrollPositionNone];
}

- (void)showAnimate {
    self.alpha = 0;
    self.tableContentView.transform = CGAffineTransformMakeTranslation(self.bounds.size.width, 0);
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.alpha = 1;
        self.tableContentView.transform = CGAffineTransformIdentity;
        
    } completion:^(BOOL finished) {
    }];
}

- (void)removeAnimate {
    [UIView animateWithDuration:0.25 animations:^{
        CGRect rect = self.tableContentView.frame;
        rect.origin.x += rect.size.width;
        self.tableContentView.frame = rect;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.tableContentView.frame = CGRectMake(self.bounds.size.width - 100, 0, 100, self.bounds.size.height);
    
    CGFloat tableViewHeight = self.videos.count * 50;
    if (tableViewHeight > self.bounds.size.height) {
        tableViewHeight = self.bounds.size.height;
    }
    
    self.tableView.frame = CGRectMake(0, self.bounds.size.height / 2 - tableViewHeight / 2, self.tableContentView.bounds.size.width, tableViewHeight);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.highlightedTextColor = [UIColor colorWithWhite:0.3 alpha:1];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    BCCPlayerItem *info = [self.videos objectAtIndex:indexPath.row];
//    cell.textLabel.text = [info type];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (self.block) {
        self.block(indexPath.row);
    }

    [self removeAnimate];

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.videos.count;
}

#pragma mark - getters setters

- (UIView *)tableContentView {
    if (_tableContentView == nil) {
        _tableContentView = [[UIView alloc] init];
        _tableContentView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    }
    return _tableContentView;
}

- (UITableView *)tableView {
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] init];
        _tableView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}


@end
