//
//  PlayerViewController.m
//  CandyPlayerDemo
//
//  Created by Candy on 2017/11/3.
//  Copyright © 2017年 MyCandy. All rights reserved.
//

#import "PlayerViewController.h"

#import <CandyPlayer/CandyPlayer.h>

@interface PlayerViewController ()
@property (weak, nonatomic) IBOutlet UIView *videoView;

@property (nonatomic, strong) BCCPlayerView *playerView;

@end

@implementation PlayerViewController

- (void)dealloc {
    NSLog(@"PlayerViewController dealloc");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.playerView.frame = self.videoView.bounds;
    [self.videoView addSubview:self.playerView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)exitPlayAction:(id)sender {
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:^{
            NSLog(@"dismiss");
        }];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)startPlayAction:(id)sender {
    BCCPlayerItem *item = [[BCCPlayerItem alloc] init];
    item.vedioURL = [NSURL URLWithString:@"http://baobab.wdjcdn.com/1456459181808howtoloseweight_x264.mp4"];
    item.title = @"video playback";
    [self.playerView playbackWithPlyerItem:item inContainerView:self.videoView];
}


- (BCCPlayerView *)playerView {
    if (_playerView == nil) {
        _playerView = [[BCCPlayerView alloc] init];
    }
    return _playerView;
}

-(BOOL)shouldAutorotate {
    return NO;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
