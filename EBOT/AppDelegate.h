//
//  AppDelegate.h
//  EBOT
//
//  Created by user on 16/9/6.
//  Copyright © 2016年 yien. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WXApi.h"

#import <BMKLocationkit/BMKLocationComponent.h>
#import <BMKLocationkit/BMKLocationAuth.h>
@interface AppDelegate : UIResponder <UIApplicationDelegate,WXApiDelegate, BMKLocationAuthDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSString *AllOrderId;

@end

