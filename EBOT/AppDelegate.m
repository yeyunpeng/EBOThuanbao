//
//  AppDelegate.m
//  EBOT
//
//  Created by user on 16/9/6.
//  Copyright © 2016年 yien. All rights reserved.
//

#import "AppDelegate.h"

#import "HomeViewController.h"
//美恰
#import <MeiQiaSDK/MQManager.h>

//分享
#import <ShareSDK/ShareSDK.h>
#import <ShareSDKConnector/ShareSDKConnector.h>
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import "WXApi.h"
#import "WeiboSDK.h"
#import <AlipaySDK/AlipaySDK.h>
//友盟推送
#import "UMessage.h"
//友盟统计
#import "UMMobClick/MobClick.h"

#import "HomeViewController.h"
#import "NoInterViewController.h"
#import "Reachability.h"
#import "BaseNaviViewController.h"

#define sdkAppKey @"12e97869cd252"
#define APP_REFRESH_NOTIFICATION @"abcdefg"

//存储唤醒时间
#define webWake @"webViewWake"

@interface AppDelegate ()

@end

@implementation AppDelegate

NSUncaughtExceptionHandler* _uncaughtExceptionHandler = nil;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // 要使用百度地图，请先启动BaiduMapManager
   
    
    [[BMKLocationAuth sharedInstance] checkPermisionWithKey:@"MGScXNQ9GVTbdN1Bmw8Oc9BSi577KGOk" authDelegate:self];
    
    //客服推送注册
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8){
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert
                                                | UIUserNotificationTypeBadge
                                                | UIUserNotificationTypeSound
                                                                                 categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    }else{
        [application registerForRemoteNotificationTypes:
         UIRemoteNotificationTypeBadge |
         UIRemoteNotificationTypeAlert |
         UIRemoteNotificationTypeSound];
    }
    
    //#error 请填写您的美洽 AppKey  账号为：sns@entgroup.cn
    [MQManager initWithAppkey:@"45308cf8f957706e509c201a2aff71f0" completion:^(NSString *clientId, NSError *error) {
    //此处账号为： app@entgroup.cn
    //[MQManager initWithAppkey:@"2e3ce9f3ee6d3f2a0d5e20125aad2abd" completion:^(NSString *clientId, NSError *error) {
        if (!error) {
            NSLog(@"美洽 SDK：初始化成功");
        } else {
            NSLog(@"美洽error:%@",error);
        }
    }];
    
    //设置 AppKey 及 LaunchOptions  友盟
    //注册推送
        [UMessage startWithAppkey:@"57451f1d67e58ebb7b003a28" launchOptions:launchOptions];
        [UMessage registerForRemoteNotifications];
        //app打开的时候 不接受弹框
        [UMessage setAutoAlert:NO];
    
    //注册统计
    UMConfigInstance.appKey = @"57451f1d67e58ebb7b003a28";
    [MobClick startWithConfigure:UMConfigInstance];//配置以上参数后调用此方法初始化SDK！
        //for log
        //[UMessage setLogEnabled:YES];
        //设置标签
        [self getUserID];
    
        //注册分享
        [ShareSDK registerApp:sdkAppKey
              activePlatforms:@[@(SSDKPlatformTypeSinaWeibo),
                                @(SSDKPlatformSubTypeWechatSession),
                                @(SSDKPlatformSubTypeWechatTimeline),
                                @(SSDKPlatformSubTypeQQFriend)]
                     onImport:^(SSDKPlatformType platformType) {
    
                         switch (platformType)
                         {
                             case SSDKPlatformTypeWechat:
                                 [ShareSDKConnector connectWeChat:[WXApi class]];
                                 break;
                             case SSDKPlatformTypeQQ:
                                 [ShareSDKConnector connectQQ:[QQApiInterface class] tencentOAuthClass:[TencentOAuth class]];
                                 break;
                             case SSDKPlatformTypeSinaWeibo:
                                 [ShareSDKConnector connectWeibo:[WeiboSDK class]];
                                 break;
                             default:
                                 break;
                         }
                     }
              onConfiguration:^(SSDKPlatformType platformType, NSMutableDictionary *appInfo) {
    
                  switch (platformType)
                  {
                      case SSDKPlatformTypeSinaWeibo:
                          //设置新浪微博应用信息,其中authType设置为使用SSO＋Web形式授权
                          [appInfo SSDKSetupSinaWeiboByAppKey:@"1549520622"
                                                    appSecret:@"40821b19d5d16c6ab8cbb9140c7cdf50"
                                                  redirectUri:@"http://www.entgroup.cn/"
                                                     authType:SSDKAuthTypeBoth];
    
                          break;
                      case SSDKPlatformTypeWechat:
                          //设置微信应用
                          [appInfo SSDKSetupWeChatByAppId:@"wxe933489420093d3a"
                                                appSecret:@"88cceb387b7c554023a1a1581e61831d"];
                          break;
                      case SSDKPlatformTypeQQ:
                          //设置QQ应用信息，其中authType设置为只用SSO形式授权
                          [appInfo SSDKSetupQQByAppId:@"1105388466"
                                               appKey:@"Kwk4sJDefA9aWBKy"
                                             authType:SSDKAuthTypeBoth];
                          break;
    
                      default:
                          break;
                  }
              }];
    
    //判断是否首次启动
        if([[NSUserDefaults standardUserDefaults] stringForKey:@"firstStart"] == nil){
            //首次启动
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstStart"];
            
            [[NSUserDefaults standardUserDefaults] setObject:[[NSUUID UUID] UUIDString] forKey:@"uuidString"];
        }
    
    HomeViewController *home = [[HomeViewController alloc] init];
    
    //监视网络状态
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        Reachability *reachability = [Reachability reachabilityWithHostName:@"www.baidu.com"];
        [reachability startNotifier];
    
    //app未运行的时候接收到推送，点击推送走这里，拿到推送的内容
        NSDictionary* pushInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (pushInfo != nil) {//进入的时候是点击通知
            NSString *urlMsg = [pushInfo valueForKey:@"urlMsg"];
            if (urlMsg.length > 0) {
                home.urlMsg = urlMsg;
            }
        }
    HomeViewController *first = [[HomeViewController alloc]init];
    //UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:home];
      BaseNaviViewController *base = [[BaseNaviViewController alloc]initWithRootViewController:first];
    
    //    让当前窗口成为主窗口并显示
    
    self.window.rootViewController = base;
    //[nav setNavigationBarHidden:YES animated:YES];
    [self.window makeKeyAndVisible];
    return YES;
}





- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSUserDefaults *users = [NSUserDefaults standardUserDefaults];
    [users setObject:[NSDate date] forKey:webWake];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [MQManager closeMeiqiaService];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [MQManager openMeiqiaService];
}
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    //上传设备deviceToken，以便美洽自建推送后，迁移推送
    [MQManager registerDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [UMessage didReceiveRemoteNotification:userInfo];
    //[UIApplication sharedApplication].applicationIconBadgeNumber = 1;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    //注册唤醒事件
    [[NSNotificationCenter defaultCenter] postNotificationName:APP_REFRESH_NOTIFICATION object:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    //退出app
}

//获取用户id 添加tag
-(void) getUserID{
    NSArray *cookiesArray = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    for (NSHTTPCookie *cookie in cookiesArray) {
        if ([cookie.name isEqualToString:@"EnBaseAppEBOT"]) {
            NSArray *list = [cookie.value componentsSeparatedByString:@"&"];
            NSString *userID = [list.firstObject componentsSeparatedByString:@"="].lastObject;
            if (userID.length > 0) {
                [UMessage addTag:userID response:^(id responseObject, NSInteger remain, NSError *error) {
                    
                }];
            }
        }
    }
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    Reachability *curReachability = [notification object];
    NSParameterAssert([curReachability isKindOfClass:[Reachability class]]);
    NetworkStatus curStatus = [curReachability currentReachabilityStatus];
    if(curStatus == NotReachable) {
        NoInterViewController *NoInter = [[NoInterViewController alloc] init];
        self.window.rootViewController = NoInter;
    }
}

@end
