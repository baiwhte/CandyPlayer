//
//  BCCNavigationController.m
//  CandyPlayerDemo
//
//  Created by 陈修武 on 2017/11/3.
//  Copyright © 2017年 MyCandy. All rights reserved.
//

#import "BCCNavigationController.h"

@interface BCCNavigationController ()

@end

@implementation BCCNavigationController

- (BOOL)shouldAutorotate {
    return self.topViewController.shouldAutorotate;
}

@end
