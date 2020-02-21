//
//  NoInterViewController.m
//  EBOT
//
//  Created by user on 16/9/6.
//  Copyright © 2016年 yien. All rights reserved.
//

#import "NoInterViewController.h"

#import "Reachability.h"
#import "HomeViewController.h"

@interface NoInterViewController ()

@end

@implementation NoInterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect rect = [UIScreen mainScreen].bounds; //屏幕尺寸
    NSString *noInterPic = @"375667.png";
    NSInteger width = rect.size.width;
    if (width == 320) {
        noInterPic = @"320480.png";
    }
    if (width == 414) {
        noInterPic = @"414736.png";
    }
    if (width == 573) {
        noInterPic = @"375667.png";
    }
    NSString *ImgPath = [[NSBundle mainBundle] pathForResource:noInterPic ofType:nil];
    UIImage *Img = [[UIImage alloc] initWithContentsOfFile:ImgPath];
    UIImageView *imgView = [[UIImageView alloc] initWithImage:Img];
    imgView.multipleTouchEnabled = YES;
    imgView.userInteractionEnabled = YES;
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(refView:)];
    [imgView addGestureRecognizer:tap];
    
    [self.view addSubview:imgView];
}

-(void)refView:(UITapGestureRecognizer *)sender{
    if ([self isNetwork]) {
        HomeViewController *home = [[HomeViewController alloc] init];
        [self presentViewController:home animated:NO completion:nil];
    }
}



/***
 * 此函数用来判断是否网络连接服务器正常
 *
 */
- (BOOL)isNetwork
{
    BOOL isExistenceNetwork;
    Reachability *reachability = [Reachability reachabilityWithHostName:@"www.baidu.com"];  // 测试服务器状态
    
    switch([reachability currentReachabilityStatus]) {
        case NotReachable:
            isExistenceNetwork = FALSE;
            break;
        case ReachableViaWWAN:
            isExistenceNetwork = TRUE;
            break;
        case ReachableViaWiFi:
            isExistenceNetwork = TRUE;
            break;
    }
    return  isExistenceNetwork;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
