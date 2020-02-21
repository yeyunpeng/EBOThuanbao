//
//  HomeViewController.m
//  EBOT
//
//  Created by user on 16/9/6.
//  Copyright © 2016年 yien. All rights reserved.
//

#import "HomeViewController.h"
#import "AppDelegate.h"
#import <ShareSDK/ShareSDK.h>
#import <ShareSDKExtension/SSEShareHelper.h>
#import <ShareSDKUI/ShareSDK+SSUI.h>
#import <ShareSDKUI/SSUIShareActionSheetStyle.h>
#import <ShareSDKUI/SSUIShareActionSheetCustomItem.h>
#import <ShareSDK/ShareSDK+Base.h>
#import <ShareSDKExtension/ShareSDK+Extension.h>

#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import "WXApi.h"
#import "WeiboSDK.h"

#import "Reachability.h"
#import "NoInterViewController.h"

#import "UMessage.h"

//永久存储类
#import "KeychainItemWrapper.h"

//美恰
#import "MQChatViewManager.h"
#import "MQChatDeviceUtil.h"
#import <MeiQiaSDK/MeiQiaSDK.h>
#import "NSArray+MQFunctional.h"
#import "MQBundleUtil.h"
#import "MQAssetUtil.h"
#import "MQImageUtil.h"
//支付
#import <AlipaySDK/AlipaySDK.h>
//apple支付
#import "MLIAPManager.h"
//浏览pdf
#import "PdfViewController.h"
//扫码
#import "SaoMaViewController.h"
//GPS定位
#import <CoreLocation/CoreLocation.h>
//百度定位
#import <BMKLocationkit/BMKLocationComponent.h>
#import "MBProgressHUD.h"
//唤醒注册编码
#define APP_REFRESH_NOTIFICATION @"abcdefg"
//存储唤醒时间
#define webWake @"webViewWake"
//存储页面加载状态，是否初次加载
#define webViewFirst @"webViewFirst"
//分享层高度
#define sharedViewH 150
//域名
//#define ebotHostUrl @"ebotapp.vwaka.com"
static NSString * const productId = @"appentgroup2018";
static NSString * orId = NULL;
static NSString * WebUrl2 = NULL;
@interface HomeViewController ()<WKNavigationDelegate,MLIAPManagerDelegate,CLLocationManagerDelegate,WKScriptMessageHandler,WKUIDelegate,passValue>
//百度定位
@property(nonatomic, strong) BMKLocationManager *locationManager;
@property(nonatomic, assign) BOOL isNeedAddr;
@property(nonatomic, assign) BOOL isNeedHotSpot;
@property(nonatomic, copy) BMKLocatingCompletionBlock completionBlock;
//GPS定位
@property (strong, nonatomic) CLLocationManager *manager;

@property (nonatomic, assign)  double currentLatitude;

@property (nonatomic, assign)  double currentLongitute;

@property (nonatomic, strong)NSString *cityNames;

/**
 *  面板
 */
@property (nonatomic, strong) UIView *panelView;
/**
 *  加载视图
 */
@property (nonatomic, strong) UIActivityIndicatorView *loadingSharedView;

//页面跳转遮罩层
@property(nonatomic,strong)UIView *loadPageView;
@property(nonatomic,strong) UIWebView *loadingGifView;

//二维码图片
@property(nonatomic,strong) UIImage *qrImg;
@property (strong, nonatomic) NSString *AllOrderId;
//下载报告
@property (strong, nonatomic) NSMutableData *data;
@property (nonatomic) long long *totalLength;
@end

//自定义用户属性
NSDictionary *clientCustomizedAttrs;

//定义截图高度
CGFloat cutImgHeight;


BOOL IsFistLoading;

@implementation HomeViewController


-(void)loadView{
    [super loadView];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [MLIAPManager sharedManager].delegate = self;
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    IsFistLoading = TRUE;
    //唤醒
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadMyWebView) name:APP_REFRESH_NOTIFICATION object:nil];
    
    self.config = [[WKWebViewConfiguration alloc] init];
    
    self.config.userContentController = [[WKUserContentController alloc] init];
    [self.config.userContentController addScriptMessageHandler:self name:@"ebotApp"];
    
    self.config.preferences = [[WKPreferences alloc] init];
    self.config.preferences.javaScriptEnabled = YES;
    self.config.preferences.javaScriptCanOpenWindowsAutomatically = false;
    
    self.config.selectionGranularity = WKSelectionGranularityCharacter;
    CGRect rect = [UIScreen mainScreen].bounds; //屏幕尺寸
    self.UIRect = rect;
    self.UIState = [[UIApplication sharedApplication] statusBarFrame];//状态栏尺
    
    self.uiWebView = [[WKWebView alloc]  initWithFrame:CGRectMake(0, self.UIState.size.height, rect.size.width, (rect.size.height-self.UIState.size.height)) configuration:self.config];
    // 设置代理
    self.uiWebView.navigationDelegate = self;
    self.uiWebView.UIDelegate = self;
    //self.uiWebView.backgroundColor=[UIColor whiteColor];
    
    //禁止滚动
    self.uiWebView.scrollView.bounces = NO;
   
    //左划回退
    //self.uiWebView.allowsBackForwardNavigationGestures = YES;
    
    //添加监视页面加载进度
    [self.uiWebView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
    // http://ebotapp.vwaka.com
    // http://ebotapp.vwaka.com/Other/VideoFrame
    //http://ebotapp.entgroup.cn
    // http://appv1.vwaka.com
 // NSString *webUrl = @"http://appv1.vwaka.com";
   // NSString *webUrl = @"http://appv1.vwaka.com/Browser";
   //NSString *webUrl = @"https://ebotapp.entgroup.cn";
     NSString *webUrl = @"https://app.endata.com.cn";
    // NSString *webUrl = @"http://ebotapptest.entgroup.cn";
    WebUrl2=webUrl;
    if (self.urlMsg.length > 0 && self.urlMsg != nil) {
        webUrl = self.urlMsg;
        //self.urlMsg = nil;
    }
    NSURL *url = [NSURL URLWithString:webUrl];
    //    NSString *path = [[NSBundle mainBundle] pathForResource:@"index.html" ofType:nil];
    //    NSURL *url = [NSURL fileURLWithPath:path];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10.0];
    //添加webview
    //self.uiWebView.hidden = FALSE;
    //添加点击事件
    UITapGestureRecognizer* singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTap.delegate = self;
    singleTap.cancelsTouchesInView = YES;
    [self.uiWebView addGestureRecognizer:singleTap];
    
    [self.view addSubview:self.uiWebView];
    //设置状态栏背景色  白色
    //self.view.backgroundColor = [UIColor colorWithRed:(255.0) green:(255.0) blue:(255.0) alpha:1];
    self.view.backgroundColor = [UIColor whiteColor];
    //添加进度条
    [self createProgress];
    self.progressView.hidden= YES;
    
    //self.uiWebView.hidden = YES;
    
    
    //添加初始loading层
    [self createLoad];
    
    //初始化设置状态为0
    self.userDefault = [NSUserDefaults standardUserDefaults];
    [self.userDefault setInteger:0 forKey:webViewFirst];
    
    //初始化分享
    [self createShared];
    
    //缓存
    [self relfCache];
    
    //初始加载页面
    [self.uiWebView loadRequest:request];
    //self.uiWebView.hidden = false;
    // 本地测试
//    NSString* path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"html"];
//    NSURL* url2 = [NSURL fileURLWithPath:path];
//    NSURLRequest* request2 = [NSURLRequest requestWithURL:url2];
//    [self.uiWebView loadRequest:request2];
    
    //初始化截图高度
    cutImgHeight = 1000;
   
    if( ([[[UIDevice currentDevice] systemVersion] doubleValue]>=7.0))
    {
        //        self.edgesForExtendedLayout=UIRectEdgeNone;
        self.navigationController.navigationBar.translucent = NO;
    }
   
    //[NSThread sleepForTimeInterval:2.0];
}
//百度定位

-(void)initLocation
{
    _locationManager = [[BMKLocationManager alloc] init];
    
    _locationManager.delegate = self;
    
    _locationManager.coordinateType = BMKLocationCoordinateTypeBMK09LL;
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    _locationManager.activityType = CLActivityTypeAutomotiveNavigation;
    _locationManager.pausesLocationUpdatesAutomatically = NO;
    _locationManager.allowsBackgroundLocationUpdates = YES;
    _locationManager.locationTimeout = 10;
    _locationManager.reGeocodeTimeout = 10;
    
}

-(void)initBlock
{
    
    __block HomeViewController *  selfs = self;
    self.completionBlock = ^(BMKLocation *location, BMKLocationNetworkState state, NSError *error)
    {
        if (error)
        {
            NSLog(@"locError:{%ld - %@};", (long)error.code, error.localizedDescription);
            
            
        }
        
        if (location.location) {//得到定位信息，添加annotation
            
            NSLog(@"LOC = %@",location.location);
            NSLog(@"LOC ID= %@",location.locationID);
            NSString *str=[NSString stringWithFormat:@"@%.6f|%.6f",location.location.coordinate.latitude, location.location.coordinate.longitude];
            NSLog(@"%@",[NSString stringWithFormat:@"当前位置信息： \n经纬度：%.6f,%.6f \n地址信息：%@ \n网络状态：%d",location.location.coordinate.latitude, location.location.coordinate.longitude, [location.rgcData description], state]);
            NSString *js = [NSString stringWithFormat:@"SysCallBack.GPSCallBack('%@','%@')",@"baidulocation",str];
            NSLog(@"%@", js);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [selfs.uiWebView evaluateJavaScript:js completionHandler:^(id _Nullable data, NSError * _Nullable error) {
                    if(error != nil) {
                        NSLog(@"%@", [error localizedDescription]);
                        
                    }
                    NSLog(@"js get version 2");
                }];
                
            });
            
            
        }
        
        if (location.rgcData) {
            NSLog(@"rgc = %@",[location.rgcData description]);
        }
        
        NSLog(@"netstate = %d",state);
    };
    
    
}


//代理方法
- (void)GPS{
    //gps定位
    // 判断定位操作是否被允许
    
    _manager = [[CLLocationManager alloc] init];
    
    [_manager requestWhenInUseAuthorization];//申请定位服务权限
    
    _manager.delegate = self;
    
    //设置定位精度
    
    _manager.desiredAccuracy = kCLLocationAccuracyBest;
    
    //定位频率,每隔多少米定位一次
    
    CLLocationDistance distance = 10.0;//十米定位一次
    
    _manager.distanceFilter = distance;
    
    [_manager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    
    
    NSLog(@"定位成功");
    
    //获取定位的坐标
    
    CLLocation *location = [locations firstObject];
    
    //获取坐标
    
    CLLocationCoordinate2D coordinate = location.coordinate;
    
    NSLog(@"定位的坐标：%f,%f", coordinate.longitude, coordinate.latitude);
    
    _currentLongitute = coordinate.longitude;
    
    _currentLatitude = coordinate.latitude;
    NSString *str=[[NSString alloc]initWithFormat:@"%f,%f", coordinate.longitude, coordinate.latitude ];
 
    //停止定位
    
    [_manager stopUpdatingLocation];
    if (_currentLongitute==0 ||_currentLatitude==0) {
        [self initBlock];
        [self initLocation];
        [_locationManager requestLocationWithReGeocode:nil withNetworkState:nil completionBlock:self.completionBlock];
        
    }else{
    NSString *js = [NSString stringWithFormat:@"SysCallBack.GPSCallBack('%@','%@')",@"GPSLocation",str];
    NSLog(@"%@", js);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.uiWebView evaluateJavaScript:js completionHandler:^(id _Nullable data, NSError * _Nullable error) {
             NSLog(@"js get version 2");
        }];
        
    });
    }
}



- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error

{
    
    NSLog(@"定位失败");
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//打电话
-(void)telPhone:(NSString *)phoneNum{
    NSString *telUrl = [NSString stringWithFormat:@"telprompt:%@",phoneNum];
    NSURL *url2 = [[NSURL alloc] initWithString:telUrl];
    [[UIApplication sharedApplication] openURL:url2];
}


//创建分享层
-(void)createShared{
    if (self.panelView == nil) {
        self.panelView = [[UIView alloc] initWithFrame:CGRectMake(0,self.UIRect.size.height, self.UIRect.size.width, sharedViewH)];
        //灰色透明
        self.panelView.backgroundColor = [UIColor colorWithRed:70.0 / 255.0 green:70.0 / 255.0 blue:70.0 / 255.0 alpha:0.5];
        //标题
        UILabel *lbShared = [[UILabel alloc] initWithFrame:CGRectMake(self.UIRect.size.width/2-25, 10, 50, 20)];
        lbShared.text = @"分享到";
        lbShared.textAlignment = NSTextAlignmentCenter;
        lbShared.adjustsFontSizeToFitWidth = YES;
        lbShared.textColor = [UIColor whiteColor];
        [self.panelView addSubview:lbShared];
        //weibo
        NSString *wbImgPath = [[NSBundle mainBundle] pathForResource:@"wb.png" ofType:nil];
        UIImage *wbImg = [[UIImage alloc] initWithContentsOfFile:wbImgPath];
        UIImageView *wb = [[UIImageView alloc] initWithImage:wbImg];
        wb.multipleTouchEnabled = YES;
        wb.userInteractionEnabled = YES;
        
        //添加点击事件   0-weibo,1-微信好友,2-微信朋友圈,3-qq
        UITapGestureRecognizer *wbTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ShareFunc:)];
        wb.tag = 0;
        
        [wb addGestureRecognizer:wbTap];
        CGSize iconSize = wbImg.size;
        //分享图标间距
        NSInteger marginLeft = (self.UIRect.size.width-iconSize.width*4)/5;
        CGRect imgRect = wb.frame;
        imgRect.origin.x = marginLeft;
        //分享图标margin-top
        imgRect.origin.y = 60;
        wb.frame = imgRect;
        [self.panelView addSubview:wb];
        //weixin
        NSString *wxImgPath = [[NSBundle mainBundle] pathForResource:@"wx.png" ofType:nil];
        UIImage *wxImg = [[UIImage alloc] initWithContentsOfFile:wxImgPath];
        UIImageView *wx = [[UIImageView alloc] initWithImage:wxImg];
        wx.userInteractionEnabled = YES;
        wx.multipleTouchEnabled = YES;
        UITapGestureRecognizer *wxTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ShareFunc:)];
        wx.tag = 1;
        [wx addGestureRecognizer:wxTap];
        imgRect.origin.x = marginLeft*2+imgRect.size.width;
        wx.frame = imgRect;
        [self.panelView addSubview:wx];
        //weixin line
        NSString *wxLineImgPath = [[NSBundle mainBundle] pathForResource:@"wxLine.png" ofType:nil];
        UIImage *wxLineImg = [[UIImage alloc] initWithContentsOfFile:wxLineImgPath];
        UIImageView *wxLine = [[UIImageView alloc] initWithImage:wxLineImg];
        wxLine.userInteractionEnabled = YES;
        wxLine.multipleTouchEnabled = YES;
        UITapGestureRecognizer *lineTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ShareFunc:)];
        wxLine.tag = 2;
        [wxLine addGestureRecognizer:lineTap];
        imgRect.origin.x = marginLeft*3+imgRect.size.width*2;
        wxLine.frame = imgRect;
        [self.panelView addSubview:wxLine];
        //qq
        NSString *qqImgPath = [[NSBundle mainBundle] pathForResource:@"qq.png" ofType:nil];
        UIImage *qqImg = [[UIImage alloc] initWithContentsOfFile:qqImgPath];
        UIImageView *qq = [[UIImageView alloc] initWithImage:qqImg];
        qq.userInteractionEnabled = YES;
        qq.multipleTouchEnabled = YES;
        UITapGestureRecognizer *qqTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ShareFunc:)];
        qq.tag = 3;
        [qq addGestureRecognizer:qqTap];
        imgRect.origin.x = marginLeft*4+imgRect.size.width*3;
        qq.frame = imgRect;
       
        [self.panelView addSubview:qq];
        
        [self.view addSubview:self.panelView];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    [self showLoadingView:NO];
    return NO;
}


-(void)handleSingleTap:(UITapGestureRecognizer *)sender{
    [self showLoadingView:NO];
}
//http://ebotapp.vwaka.com/Content/Images/Start/5.png
//初始层
-(void)createLoad{
    if (self.loadingView == nil) {
        self.loadingView = [[UIView alloc] initWithFrame:self.UIRect];
        UIImageView *imgview = [[UIImageView alloc] initWithFrame:self.UIRect];
        NSString *picName = @"6p.png";
        NSInteger width = self.UIRect.size.width;
        NSInteger height = self.UIRect.size.height;
        if (width == 320) {
            picName = @"5.png";
        }
        if (width == 375 && height!=812) {
            picName = @"6.png";
        }
        if (width == 375 && height==812) {
            picName = @"iPhoneX@3x.png";
        }
        if (width >= 414) {
            picName = @"6p.png";
        }
//        if (width >= 414) {
//            picName = @"iPhoneX@3x.png";
//        }
        //        NSString *QRImgURl = [NSString stringWithFormat:@"http://ebotapp.vwaka.com/Content/Images/Start/%@",picName];
        //        UIImage *img = [self getImageFromURL:QRImgURl];
        //        if (img == nil) {
        NSString *imgpath = [[NSBundle mainBundle] pathForResource:picName ofType:nil];
        imgview.image = [[UIImage alloc] initWithContentsOfFile:imgpath];
        
        //        }else{
        //            imgview.image = img;
        //        }
        self.loadingView = imgview;
        [self.view addSubview:self.loadingView];
        
    }
}

//创建进度条
-(void)createProgress{
    if (!self.progressView) {
        self.progressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
        CGRect rectState  = [[UIApplication sharedApplication] statusBarFrame];//状态栏尺
        self.progressView.frame = CGRectMake(0,(rectState.size.height), self.view.bounds.size.width,1);
        //设置进度条的色彩
        [self.progressView setTrackTintColor:[UIColor clearColor]];
        
        self.progressView.progressTintColor = [UIColor blueColor];
        [self.view addSubview:self.progressView];
    }
}


//监控加载进度
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        if (object == self.uiWebView) {
            if (self.uiWebView.estimatedProgress >= 1.0) {
                //隐藏
                self.progressView.hidden = YES;
                self.progressView.progress = 0;
            }
            // 添加进度数值
            [self.progressView setProgress:self.uiWebView.estimatedProgress animated:YES];
        }
        else
        {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
}
//拦截非法跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
//    NSString *hostname = navigationAction.request.URL.host.lowercaseString;
//    if (navigationAction.navigationType == WKNavigationTypeLinkActivated && ![hostname containsString:ebotHostUrl]) {
//        decisionHandler(WKNavigationActionPolicyCancel);
//    }else {
//        decisionHandler(WKNavigationActionPolicyAllow);
//    }
    //如果是跳转一个新页面
    if (navigationAction.targetFrame == nil) {
        [webView loadRequest:navigationAction.request];
        decisionHandler(WKNavigationActionPolicyCancel);
        NSLog(@"nil tag %@", [navigationAction.request.URL  absoluteString]);
        return;
    }
    
    NSURL *url = navigationAction.request.URL;

    //decisionHandler(WKNavigationActionPolicyAllow);
    NSLog(@"%@", [url absoluteString]);
    NSLog(@"scheme %@", url.scheme);
    WKNavigationActionPolicy policy = WKNavigationActionPolicyAllow;
    
    //if([url.scheme isEqualToString:@"itms-appss"]) {
      if([url.scheme isEqualToString:@"https"] && [[url absoluteString] hasPrefix:@"https://itunes.apple.com"]) {
      
        //[[UIApplication sharedApplication] openURL:url ];
        
        
        if([[UIApplication sharedApplication] canOpenURL:url])
        {
            //NSDictionary *option =@{ UIApplicationOpenURLOptionUniversalLinksOnly:@YES};
            NSDictionary *option =@{ };

            [[UIApplication sharedApplication] openURL:url options:option completionHandler:nil];
            NSLog(@"sharedApplication");
        }
        else
        {
            NSLog(@"can not open");
        }
        
        policy =WKNavigationActionPolicyCancel;
    }

    
    
    NSLog(@"Leve decisionHandler");

    decisionHandler(policy);
   
}


// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    //记录页面加载次数
    NSInteger viewCount = [self.userDefault integerForKey:webViewFirst]+1;
    [self.userDefault setInteger:viewCount forKey:webViewFirst];
    if (viewCount > 1) {
        //显示进度条
        self.progressView.hidden = NO;
    }
}
// 当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    //NSLog(@"内容开始返回------");
}
// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
  
    //判断当前页面是否为绑定手机页面
    if ([[webView.URL path] isEqualToString:@"/Login/Index"]) {
        //把唯一标识设置为页面上input元素的值
        [self.uiWebView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('iptOnlyID').value = '%@';",[self getClientID]] completionHandler:nil];
    }
    //禁止长按弹出菜单
    [self.uiWebView evaluateJavaScript:@"document.documentElement.style.webkitUserSelect='none';" completionHandler:nil];
    [self.uiWebView evaluateJavaScript:@"document.documentElement.style.webkitTouchCallout='none';" completionHandler:nil];
    //设置app版本号
    //[self.uiWebView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('_APPVersionHid').value='%s';","1.3.2"] completionHandler:nil];
    
    [self.uiWebView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('_APPVersionHid').value='%s';","2.4.6"] completionHandler:nil];
    //NSInteger viewCount = [self.userDefault integerForKey:webViewFirst];
   //if (viewCount == 1) {
   //     self.uiWebView.hidden = NO;
   //     self.loadingView.hidden = YES;
    //}
    
    self.progressView.progress = 0;
    self.progressView.hidden = YES;

    if(IsFistLoading == TRUE) {
        //self.uiWebView.hidden = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            self.loadingView.hidden = YES;
            IsFistLoading = FALSE;
            [self.loadingView removeFromSuperview];
        });
        
        
        //[self.loadingView release];
    }
      NSLog(@"页面加载完成之后------");
    
}
// 页面加载失败时调用
-(void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
        //NoInterViewController *noInter = [[NoInterViewController alloc] init];
        //[self presentViewController:noInter animated:NO completion:nil];
}

-(void)webViewWebContentProcessDidTerminate:(WKWebView *)webView
{
    NSLog(@"webViewWebContentProcessDidTerminate");
    [webView reload];
}


/**
 *  web界面中有弹出警告框时调用
 *
 *  @param webView           实现该代理的webview
 *  @param message           警告框中的内容
 *  @param frame             主窗口
 *  @param completionHandler 警告框消失调用
 */
-(void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"消息提示"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"好"
                                              otherButtonTitles:nil];
    [alertView show];
    completionHandler();
}

/*
- (void)webView:(WKWebView *)webView WebContentProcessDidTerminate:(WKWebView *)webView API_AVAILABLE(macosx(10.11), ios(9.0)){

}*/
//扫码回调
-(void)passedValue:(NSString *)inputValue{
   NSLog(@"qqqqqqqq%@", self.AllOrderId);
    NSString *js = [NSString stringWithFormat:@"SysCallBack.QrCallBack('%@')",inputValue];
    NSLog(@"%@", js);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.uiWebView evaluateJavaScript:js completionHandler:^(id _Nullable data, NSError * _Nullable error) {
            NSLog(@"js get version 2");
        }];
        
    });
}
#pragma mark 监听通知
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    //检测是否装了微信软件
//    if ([WXApi isWXAppInstalled])
//    {
    
        //监听通知WxPay
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getOrderPayResult:) name:@"WXPay" object:nil];
    //监听通知AliPay
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getOrderAliPayResult:) name:@"AliPay" object:nil];
    //}
}
#pragma mark - 事件

#pragma mark - ================ MLIAPManager Delegate =================

- (void)receiveProduct:(SKProduct *)product {
    
    if (product != nil) {
        //购买商品
        if (![[MLIAPManager sharedManager] purchaseProduct:product]) {
            UIAlertController *aleView=[UIAlertController alertControllerWithTitle:@"失败" message:@"您禁止了应用内购买权限,请到设置中开启" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancel=[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:nil];
            [aleView addAction:cancel];
            [self presentViewController:aleView animated:YES completion:nil];
            
        }
    } else {
        UIAlertController *aleView=[UIAlertController alertControllerWithTitle:@"失败" message:@"无法连接App store!" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel=[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:nil];
        [aleView addAction:cancel];
        [self presentViewController:aleView animated:YES completion:nil];
    }
}

- (void)successedWithReceipt:(NSData *)transactionReceipt {
    NSLog(@"购买成功");
    
   NSString *transactionReceiptString = [transactionReceipt base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    
    NSString *recpStr=[NSString stringWithFormat:@"OrderID=%@&receipt=%@",orId,transactionReceiptString];
    NSLog(@"aaaaaaa:_______%@",recpStr);
    NSData *data =[recpStr dataUsingEncoding:NSUTF8StringEncoding];
    if ([transactionReceiptString length] > 0) {
        
        NSURLSession *session = [NSURLSession sharedSession];
        // 创建 URL
         NSString *Str=[NSString stringWithFormat:@"%@/API/Mine/ApplePay/VerifyReceip",WebUrl2];
        NSLog(@"url****:%@",Str);
        NSURL *url = [NSURL URLWithString:Str];
        // 创建 request
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        // 请求方法
        request.HTTPMethod = @"POST";
        // 请求体
        request.HTTPBody = data;
        // 创建任务 task
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            // 获取数据后解析并输出
            NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
              NSDictionary *str = [dic objectForKey:@"Data"];
             NSString *str2 = [str objectForKey:@"Rs"];
            [self back:str2];
            
          
           NSLog(@"%@",[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil]);
        }];
        // 启动任务
        [task resume];

        // 向自己的服务器验证购买凭证（此处应该考虑将凭证本地保存,对服务器有失败重发机制）
        /**
         服务器要做的事情:
         接收ios端发过来的购买凭证。
         判断凭证是否已经存在或验证过，然后存储该凭证。
         将该凭证发送到苹果的服务器验证，并将验证结果返回给客户端。
         如果需要，修改用户相应的会员权限
         */
      
        
    }
}
- (void)back:(NSString *)backStr{
    NSString *factory_id = [NSString stringWithFormat:@"%@",backStr];
    if ([factory_id isEqualToString:@"1"]) {
        NSLog(@"购买成功233333");
        [[MLIAPManager sharedManager] finishTransaction];
        NSLog(@"购买成功444444");
        NSString *js = [NSString stringWithFormat:@"SysCallBack.PayCallBack('%@','%@')",@"Applesuccess",orId];
        NSLog(@"%@", js);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.uiWebView evaluateJavaScript:js completionHandler:^(id _Nullable data, NSError * _Nullable error) {
                NSLog(@"js get version 3");
            }];
        });
      
    }
}
- (void)failedPurchaseWithError:(NSString *)errorDescripiton {
    NSLog(@"购买失败");
    //[MBProgressHUD hideHUDForView:self.view animated:YES];
    UIAlertController *aleView=[UIAlertController alertControllerWithTitle:@"失败" message:errorDescripiton preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel=[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:nil];
    [aleView addAction:cancel];
    [self presentViewController:aleView animated:YES completion:nil];
   
}
//js交互
-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    
    if (message.body != nil) {
        NSObject *obj = (NSObject*)message.body;
        NSString *typeStr = [obj valueForKey:@"type"];
        //apple支付
        if ([typeStr isEqualToString: @"ApplePay"]) {
            NSString *orderId = [obj valueForKey:@"OrderID"];
            orId=orderId;
            [[MLIAPManager sharedManager] requestProductWithId:productId];
//            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//            hud.label.text = @"支付处理中...";
        
        }
        
        //扫码
        if ([typeStr isEqualToString: @"Qr"]) {
            
          
            SaoMaViewController *s=[[SaoMaViewController alloc]init];
            s.delegate = self;
            [self.navigationController pushViewController:s animated:YES];
            
        }
        //gps定位
        if ([typeStr isEqualToString: @"GPS"]) {
            NSLog(@"aaaaaaaaa111111111");
            [self GPS];
        }
        //浏览PDF
        if ([typeStr isEqualToString: @"Pdf"]) {
            
            NSString *Url = [obj valueForKey:@"Url"];
            PdfViewController *pdf=[[PdfViewController alloc]init];
            pdf.urlStr=Url;
            NSLog(@"111111%@",Url);
            [self.navigationController pushViewController:pdf animated:YES];
        }
        //分享
        if ([typeStr isEqualToString: @"shared"]) {
            NSLog(@"***************************************2");
            //[self.uiWebView evaluateJavaScript:@"document.getElementById('iframePage').contentWindow.onunload_handler()" completionHandler:nil];
            //window.webkit.messageHandlers.ebotApp.postMessage({ 'type': 'shared','height': '800' });
            if ([obj valueForKey:@"imgData"] != nil) {
                // 页面分享图片
//                self.urlSharedMsg = nil;
//                NSString *heightStr = [obj valueForKey:@"height"];
//                float heightFloat = [heightStr floatValue];
//                cutImgHeight = heightFloat;
//                if (heightFloat == 0) {
//                    cutImgHeight = 1000;
//                }
                self.cutImg = [self baseToImage:[obj valueForKey:@"imgData"]];
            }
            if([obj valueForKey:@"msgTitle"]!=nil){
                //文章标题
                self.msgTitle = [obj valueForKey:@"msgTitle"];
            }
            if([obj valueForKey:@"msgUrl"]!=nil){
                // 分享文章
                self.urlSharedMsg = [obj valueForKey:@"msgUrl"];
            }
            
            self.uiWebView.frame = CGRectMake(0, self.UIState.size.height, self.UIRect.size.width, cutImgHeight);
            [self performSelector:@selector(cutScreen) withObject:nil afterDelay:0.5];
            
            
        }
        //分享
//         window.webkit.messageHandlers.ebotApp.postMessage({ 'type': 'sharedurl','msgTitle': 标题, 'pageUrl': 地址url, 'imgUrl': ,图片url, 'msgDesc': ,介绍内容 });
       if ([typeStr isEqualToString: @"sharedurl"]) {
           NSLog(@"***************************************");
            //[self.uiWebView evaluateJavaScript:@"document.getElementById('iframePage').contentWindow.onunload_handler()" completionHandler:nil];
            //window.webkit.messageHandlers.ebotApp.postMessage({ 'type': 'shared','height': '800' });
        
            if ([obj valueForKey:@"imgUrl"] != nil) {
           
                self.cutImg = [self baseToImage:[obj valueForKey:@"imgUrl"]];
            }
            if([obj valueForKey:@"msgTitle"]!=nil){
                //文章标题
                self.msgTitle = [obj valueForKey:@"msgTitle"];
            }
        if([obj valueForKey:@"pageUrl"]!=nil){
            //地址url
            self.urlMsg = [obj valueForKey:@"pageUrl"];
        }
            if([obj valueForKey:@"msgDesc"]!=nil){
                // 分享文章
                self.urlSharedMsg = [obj valueForKey:@"msgDesc"];
                
            }
            
            self.uiWebView.frame = CGRectMake(0, self.UIState.size.height, self.UIRect.size.width, cutImgHeight);
           [self showLoadingView:YES];
            //[self performSelector:@selector(cutScreen) withObject:nil afterDelay:0.5];
            
            
        }
        //调用打电话方法
        if ([typeStr isEqualToString: @"tel"]) {
           
            //window.webkit.messageHandlers.ebotApp.postMessage({ 'type': 'tel','phoneNum':'电话号码' });
            NSString *phoneNum = [obj valueForKey:@"phoneNum"];
            [self telPhone:phoneNum];
        }
        //调用打电话方法
        if ([typeStr isEqualToString: @"downpdf"]) {
            //  判断文件存不存在
            // 文件名
            NSString  *filename = @"zz.pdf";
            
            NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
            
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            NSString *filePath = [documentsDirectory stringByAppendingPathComponent:filename];
            
            if(![fileManager fileExistsAtPath:filePath])
            {
                NSLog(@"文件不存在");
            }else{
                NSLog(@"文件存在");
            }
            // 下载网址  我这个是假的
            NSURL *url = [NSURL URLWithString:@"http://v2001.enbase.entgroup.cn/Report/EnReport/Report/File/%E5%A5%B3%E6%80%A7%E7%BB%BC%E8%89%BA%E6%95%B0%E6%8D%AE%E7%A0%94%E7%A9%B6%E6%8A%A5%E5%91%8A15.pdf"];
            
            //创建管理类NSURLSessionConfiguration
            NSURLSessionConfiguration *config =[NSURLSessionConfiguration defaultSessionConfiguration];
            
            //初始化session并制定代理
            NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
            
            NSURLSessionDataTask *task = [session dataTaskWithURL:url];
            
            // 开始
            [task resume];
            
        }
        
        //客服
        if ([typeStr isEqualToString: @"services"]) {
            
            MQChatViewManager *chatViewManager = [[MQChatViewManager alloc] init];
            //界面设置
            [chatViewManager.chatViewStyle setEnableOutgoingAvatar:false];
            [chatViewManager.chatViewStyle setEnableRoundAvatar:YES];
            [chatViewManager.chatViewStyle setEnableOutgoingAvatar:YES];
            //用户属性
            [chatViewManager setClientInfo:@{@"avatar":@"http://ebotapp.entgroup.cn/Content/Images/kehu.png"}];
            
            [chatViewManager pushMQChatViewControllerInViewController:self];
            
            [chatViewManager setRecordMode:MQRecordModeDuckOther];
            [chatViewManager setPlayMode:MQPlayModeMixWithOther];
        }
        //页面退出登录  删除tag
        if ([typeStr isEqualToString:@"logout"]) {
            @try {
                NSString *userID = [self getUserID];
                if (userID.length > 0) {
                    [UMessage removeTag:userID response:^(id responseObject, NSInteger remain, NSError *error) {
                    }];
                }
            } @catch (NSException *exception) {
                
            } @finally {
                NSLog(@"sssssss");
            }
            
        }
        
        if ([typeStr isEqualToString:@"version"]) {
           
            if ([obj valueForKey:@"callback"] != nil) {
                NSString *js = [NSString stringWithFormat:@"%@('%@');", [obj valueForKey:@"callback"], @"2"];
                NSLog(@"%@", js);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.uiWebView evaluateJavaScript:js completionHandler:^(id _Nullable data, NSError * _Nullable error) {
                        NSLog(@"js get version 2");
                    }];
                    
                });
            }
        }
        
        
    }
}
#pragma mark  ====  接收到数据调用
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    //允许继续响应
    completionHandler(NSURLSessionResponseAllow);
    //获取文件的总大小
    self.totalLength = response.expectedContentLength;
}


#pragma mark  ===== 接收到数据调用
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    
    //将每次接受到的数据拼接起来
    [self.data appendData:data];
    //计算当前下载的长度
    NSInteger nowlength = self.data.length;
    
    //  可以用些 三方动画
    //    CGFloat value = nowlength*1.0/self.totalLength;
}



#pragma mark ====  下载用到的 代理方法
#pragma mark *下载完成调用
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    NSLog(@"%@",[NSThread currentThread]);
    //将下载后的数据存入文件(firstObject 无数据返回nil，不会导致程序崩溃)
    
    NSString *destPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    //destPath = [destPath stringByAppendingPathComponent:@"my.zip"];
    
    destPath = [destPath stringByAppendingPathComponent:@"zz.pdf"];
    
    NSLog(@"ccc  %@",destPath);
    
    //将下载的二进制文件转成入文件
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDownLoad =  [manager createFileAtPath:destPath contents:self.data attributes:nil];
    
    if (isDownLoad) {
        NSLog(@"OK");
    }else{
        NSLog(@"Sorry");
    }
    //    NSLog(@"下载完成");
}
- (UIImage *) baseToImage: (NSString *) imgSrc
{
    NSURL *url = [NSURL URLWithString: imgSrc];
    NSData *data = [NSData dataWithContentsOfURL: url];
    UIImage *image = [UIImage imageWithData: data];
    
    return image;
}
//截屏并保存图片
- (void)cutScreen{
    //UIGraphicsBeginImageContextWithOptions(self.uiWebView.frame.size,NO,0.0);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.view.frame.size.width, cutImgHeight), YES, 0.0);
    for(UIView *subview in self.uiWebView.subviews)
    {
        [subview drawViewHierarchyInRect:subview.bounds afterScreenUpdates:YES];
    }
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //self.cutImg = [self combine:newImage];
    
    self.uiWebView.frame = CGRectMake(0, self.UIState.size.height, self.UIRect.size.width, (self.UIRect.size.height-self.UIState.size.height));
    
    [self showLoadingView:YES];
    //[MBProgressHUD hideHUDForView:self.view animated:YES];
}


-(void)ShareFunc:(UITapGestureRecognizer *)sender{
    UITapGestureRecognizer *tapSingle = (UITapGestureRecognizer*)sender;
    NSInteger sharedType = tapSingle.view.tag;
    
    //1、创建分享参数
    NSMutableDictionary *shareParams = [NSMutableDictionary dictionary];
    //设置分享用客户端打开  不然有些平台分享会报错
    [shareParams SSDKEnableUseClientShare];
    
    //NSArray* imageArray = @[[UIImage imageNamed:@"2.jpg"]];
    if (self.cutImg)
    {
        //图片分享
        if (self.urlSharedMsg == nil) {
            [shareParams SSDKSetupShareParamsByText:self.msgTitle
                                             images:self.cutImg
                                                url:[NSURL URLWithString:@"http://www.entgroup.com.cn"]
                                              title:@"艺恩数据"
                                               type:SSDKContentTypeImage];
            //关闭对比打开div
            [self.uiWebView evaluateJavaScript:@"_APPShareEnd()" completionHandler:nil];
            
        }else{
            //文章分享
            [shareParams SSDKSetupShareParamsByText:self.urlSharedMsg
                                             images:self.cutImg
                                                url:[NSURL URLWithString:self.urlMsg]
                                              title:self.msgTitle
                                               type:SSDKContentTypeWebPage];
        }
    }else{
        return;
    }
    SSDKPlatformType type;
    //  0-weibo,1-微信好友,2-微信朋友圈,3-qq
    switch (sharedType) {
        case 2:
            //微信朋友圈分享
            type = SSDKPlatformSubTypeWechatTimeline;
            break;
        case 1:
            //微信好友
            type = SSDKPlatformSubTypeWechatSession;
            break;
        case 0:
            //微博分享
            type = SSDKPlatformTypeSinaWeibo;
            break;
        case 3:
            //qq分享
            type = SSDKPlatformSubTypeQQFriend;
            break;
        default:
            break;
    }
    //分享
    [ShareSDK share:type
         parameters:shareParams
     onStateChanged:^(SSDKResponseState state, NSDictionary *userData, SSDKContentEntity *contentEntity, NSError *error) {
         [self showLoadingView:NO];
         switch (state) {
             case SSDKResponseStateSuccess:
             {
                 //                 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"分享成功"
                 //                                                                     message:nil
                 //                                                                    delegate:nil
                 //                                                           cancelButtonTitle:@"确定"
                 //                                                           otherButtonTitles:nil];
                 //[alertView show];
                 break;
             }
             case SSDKResponseStateFail:
             {
                 //                 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"分享失败"
                 //                                                                     message:[NSString stringWithFormat:@"%@", error]
                 //                                                                    delegate:nil
                 //                                                           cancelButtonTitle:@"确定"
                 //                                                           otherButtonTitles:nil];
                 //                 [alertView show];
                 break;
             }
             case SSDKResponseStateCancel:
             {
                 //                 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"分享已取消"
                 //                                                                     message:nil
                 //                                                                    delegate:nil
                 //                                                           cancelButtonTitle:@"确定"
                 //                                                           otherButtonTitles:nil];
                 //[alertView show];
                 break;
             }
             default:
                 break;
         }
     }];
    
}


// 唤醒刷新app
-(void)reloadMyWebView{
    @try {
        self.userDefault = [NSUserDefaults standardUserDefaults];
        if ([self.userDefault objectForKey:webWake] == nil) {
        //记录唤醒时间点
        [self.userDefault setObject:[NSDate date] forKey:webWake];
        }else{
            NSDate *prevDate  = (NSDate*)[self.userDefault objectForKey:webWake];
            //唤醒时间间隔大于30分钟就刷新
            if ([[NSDate date] timeIntervalSinceDate:prevDate] > 1800) {
                [self.uiWebView reload];
            }
        }
    } @catch (NSException *exception) {
    }
}

//缓存处理
-(void)relfCache{
    @try {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"YYYY-MM-dd"];
        NSDate *datenow = [NSDate date];
        NSString *currentTimeString = [formatter stringFromDate:datenow];
        self.userDefault = [NSUserDefaults standardUserDefaults];
        if ([self.userDefault objectForKey:currentTimeString] == nil) {
            if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0){
                NSSet *websiteDataTypes= [NSSet setWithArray:@[
                                                               WKWebsiteDataTypeDiskCache,
                                                               WKWebsiteDataTypeMemoryCache,
                                                               WKWebsiteDataTypeCookies
                                                               ]];
                
                NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
                [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{}];
                [[NSURLCache sharedURLCache] removeAllCachedResponses];
            }else{
                NSString *libraryDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                NSString *bundleId  =  [[[NSBundle mainBundle] infoDictionary]
                                        objectForKey:@"CFBundleIdentifier"];
                NSString *webkitFolderInLib = [NSString stringWithFormat:@"%@/WebKit",libraryDir];
                NSString *webKitFolderInCaches = [NSString
                                                  stringWithFormat:@"%@/Caches/%@/WebKit",libraryDir,bundleId];
                NSString *webKitFolderInCachesfs = [NSString
                                                    stringWithFormat:@"%@/Caches/%@/fsCachedData",libraryDir,bundleId];
                NSError *error;
                /* iOS8.0 WebView Cache的存放路径 */
                [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCaches error:&error];
                [[NSFileManager defaultManager] removeItemAtPath:webkitFolderInLib error:nil];
                /* iOS7.0 WebView Cache的存放路径 */
                [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCachesfs error:&error];
                [[NSURLCache sharedURLCache] removeAllCachedResponses];
            }
            
            [self.userDefault setObject:[NSDate date] forKey:currentTimeString];
        }
            
    } @catch (NSException *exception) {
        
    }
}

//获取手机唯一标示
-(NSString*)getClientID{
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"deviceIdentifier" accessGroup:nil];
    NSString *uuidString = [wrapper objectForKey:(id)kSecAttrAccount];
    if (uuidString.length > 0) {
        return uuidString;
    }else{
        NSString *newUUID = [[NSUserDefaults standardUserDefaults] stringForKey:@"uuidString"];
        [wrapper setObject:newUUID forKey:(id)kSecAttrAccount];
        return newUUID;
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //释放资源,防止闪退
    self.uiWebView.UIDelegate=nil;
}

/**
 *  显示分享层
 *
 *  @param flag YES 显示，NO 不显示
 */
- (void)showLoadingView:(BOOL)flag
{
    
    if (flag)
    {
        if (self.panelView.frame.origin.y == self.UIRect.size.height) {
            [UIView animateWithDuration:0.2 animations:^{
                [self.panelView setFrame:CGRectMake(0, self.UIRect.size.height-sharedViewH, self.UIRect.size.width, sharedViewH)];
            }];
            
            //[self.uiWebView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('_PageFixedBtn').style.display = 'none';"] completionHandler:nil];
        }
    }
    else
    {
        if (self.panelView.frame.origin.y == (self.UIRect.size.height-sharedViewH)) {
            [UIView animateWithDuration:0.2 animations:^{
                [self.panelView setFrame:CGRectMake(0, self.UIRect.size.height, self.UIRect.size.width, sharedViewH)];
            }];
            [self.uiWebView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('_PageFixedBtn').style.display = 'block';"] completionHandler:nil];
            //关闭对比打开div
            [self.uiWebView evaluateJavaScript:@"_APPShareEnd()" completionHandler:nil];
        }
    }
}
//请求线上图片
-(UIImage *) getImageFromURL:(NSString *)fileURL {
    UIImage * result;
    NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:fileURL]];
    result = [UIImage imageWithData:data];
    return result;
}


//拼接分享图和二维码图      http://ebotapp.vwaka.com/Content/Images/QrCode/QR282.png
- (UIImage *) combine:(UIImage*)topImage{
    CGFloat width = topImage.size.width;
    //高度 -49  页面底部菜单高49
    CGFloat height = topImage.size.height;
    NSString *QRName = @"QR375.png";
    if (width == 320) {
        QRName = @"QR320.png";
    }
    if(width == 375){
        QRName = @"QR375.png";
    }
    if(width >= 414){
        QRName = @"QR414.png";
    }
    if (self.qrImg == nil) {
        NSLog(@"ceshi:1111111111111111");
        NSString *imgpath = [[NSBundle mainBundle] pathForResource:QRName ofType:nil];
        self.qrImg  = [[UIImage alloc] initWithContentsOfFile:imgpath];
    }
    // 底部二维码图的高度   ip6 plus缩小3倍  其它缩小2倍
    NSInteger qrHeight = self.qrImg.size.height / 2;
    if(width >= 414){
        qrHeight = self.qrImg.size.height / 3;
    }
    
    // -49 是去掉页面底部菜单栏
    CGSize offScreenSize = CGSizeMake(width, (height + self.qrImg.size.height -49 - qrHeight));
    
    //UIGraphicsBeginImageContext(offScreenSize);
    UIGraphicsBeginImageContextWithOptions(offScreenSize,NO,0.0);
    
    CGRect rect = CGRectMake(0, 0, width, height);
    [topImage drawInRect:rect];
    
    rect.origin.y += topImage.size.height - 49;
    rect.size.height = qrHeight;
    
    [self.qrImg drawInRect:rect];
    
    UIImage* imagez = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return imagez;
}


//设置状态栏字体为白色
//-(UIStatusBarStyle)preferredStatusBarStyle{
//    return UIStatusBarStyleLightContent;
//}

//获取用户id
-(NSString *) getUserID{
    NSString *uID = nil;
    NSArray *cookiesArray = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    for (NSHTTPCookie *cookie in cookiesArray) {
        if ([cookie.name isEqualToString:@"EnBaseAppEBOT"]) {
            NSArray *list = [cookie.value componentsSeparatedByString:@"&"];
            uID = [list.firstObject componentsSeparatedByString:@"="].lastObject;
        }
    }
    return uID;
}
- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
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
