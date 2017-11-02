//
//  ViewController.m
//  CandyPlayerDemo
//
//  Created by 陈修武 on 2017/11/1.
//  Copyright © 2017年 MyCandy. All rights reserved.
//

#import "ViewController.h"

#import <BCCPlayerView.h>

@interface ViewController ()


@property (weak, nonatomic) IBOutlet UIView *videoView;

@property (nonatomic, strong) BCCPlayerView *playerView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.playerView.frame = self.videoView.bounds;
    [self.videoView addSubview:self.playerView];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startPlaybackAction:(id)sender {
    BCCPlayerItem *item = [[BCCPlayerItem alloc] init];
    item.vedioURL = [NSURL URLWithString:@"http://baobab.wdjcdn.com/1456459181808howtoloseweight_x264.mp4"];
    [self.playerView playbackWithPlyerItem:item inContainerView:nil];
}

- (BCCPlayerView *)playerView {
    if (_playerView == nil) {
        _playerView = [[BCCPlayerView alloc] init];
    }
    return _playerView;
}

- (BOOL)shouldAutorotate {
    return NO;
}


@end
