//
//  MLIAPManager.m
//  MLIAPurchaseManager
//
//  Created by mali on 16/5/14.
//  Copyright © 2016年 mali. All rights reserved.
//

#import "MLIAPManager.h"

@interface MLIAPManager() <SKProductsRequestDelegate, SKPaymentTransactionObserver> {
    SKProduct *myProduct;
}

@property (nonatomic, strong) SKPaymentTransaction *currentTransaction;

@end

@implementation MLIAPManager

#pragma mark - ================ Singleton ================= 

+ (instancetype)sharedManager {
    
    static MLIAPManager *iapManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        iapManager = [MLIAPManager new];
    });
    
    return iapManager;
}

#pragma mark - ================ Public Methods =================

#pragma mark ==== 请求商品
- (BOOL)requestProductWithId:(NSString *)productId {
    
    if (productId.length > 0) {
        NSLog(@"请求商品: %@", productId);
        SKProductsRequest *productRequest = [[SKProductsRequest alloc]initWithProductIdentifiers:[NSSet setWithObject:productId]];
        productRequest.delegate = self;
        [productRequest start];
        return YES;
    } else {
        NSLog(@"商品ID为空");
    }
    return NO;
}

#pragma mark ==== 购买商品
- (BOOL)purchaseProduct:(SKProduct *)skProduct {
    
    if (skProduct != nil) {
        if ([SKPaymentQueue canMakePayments]) {
            NSLog(@"shuju:%@",skProduct);
            SKPayment *payment = [SKPayment paymentWithProduct:skProduct];
            [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
            [[SKPaymentQueue defaultQueue] addPayment:payment];
            return YES;
        } else {
            NSLog(@"失败，用户禁止应用内付费购买.");
        }
    }
    return NO;
}

#pragma mark ==== 商品恢复
- (BOOL)restorePurchase {
    
    if ([SKPaymentQueue canMakePayments]) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        [[SKPaymentQueue defaultQueue]restoreCompletedTransactions];
        return YES;
    } else {
        NSLog(@"恢复失败,用户禁止应用内付费购买.");
    }
    return NO;
}

#pragma mark ==== 结束这笔交易
- (void)finishTransaction {
	[[SKPaymentQueue defaultQueue] finishTransaction:self.currentTransaction];
}





#pragma mark - ================ SKRequestDelegate =================

- (void)requestDidFinish:(SKRequest *)request {
    if ([request isKindOfClass:[SKReceiptRefreshRequest class]]) {
        NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
        NSData *receiptData = [NSData dataWithContentsOfURL:receiptUrl];
        [_delegate successedWithReceipt:receiptData];
    }
}


#pragma mark - ================ SKProductsRequest Delegate =================

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    NSArray *myProductArray = response.products;
    if (myProductArray.count > 0) {
        myProduct = [myProductArray objectAtIndex:0];
        [_delegate receiveProduct:myProduct];
    } else {
        NSLog(@"无法获取产品信息，购买失败。");
        [_delegate receiveProduct:myProduct];
    }
}
- (void)dealloc
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

#pragma mark - ================ SKPaymentTransactionObserver Delegate =================

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
//            case SKPaymentTransactionStatePurchasing: //商品添加进列表
//                NSLog(@"商品:%@被添加进购买列表",myProduct.localizedTitle);
//                break;
//            case SKPaymentTransactionStatePurchased://交易成功
//                [self completeTransaction:transaction];
//                break;
//            case SKPaymentTransactionStateFailed://交易失败
//                [self failedTransaction:transaction];
//                break;
//            case SKPaymentTransactionStateRestored://已购买过该商品
//                break;
//            case SKPaymentTransactionStateDeferred://交易延迟
//                break;
//            default:
//                break;
            case SKPaymentTransactionStatePurchased:
                NSLog(@"交易完成");
                [self completeTransaction:transaction];
                [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
                break;
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"商品添加进列表");
                
                break;
            case SKPaymentTransactionStateRestored:{
                NSLog(@"已经购买过商品");
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                
//                UIAlertView *alerView = [[UIAlertView alloc] initWithTitle:@"已经购买过该商品" message:nil delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil];
//                [alerView show];
                
            }
                
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"交易失败");
                //[self failedTransaction:transaction];
                  [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                
                
                break;
            default:
                break;
    
        }
    }
}

#pragma mark - ================ Private Methods =================

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    // 验证凭据，获取到苹果返回的交易凭据
    // appStoreReceiptURL iOS7.0增加的，购买交易完成后，会将凭据存放在该地址
   
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    // 从沙盒中获取到购买凭据
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
      NSString * str=[[NSString alloc]initWithData:transaction.transactionReceipt encoding:NSUTF8StringEncoding];
    NSData *data =[str dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"*******:%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    [_delegate successedWithReceipt:data];
    self.currentTransaction = transaction;
    
}


- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
    if (transaction.error.code != SKErrorPaymentCancelled && transaction.error.code != SKErrorUnknown) {
        [_delegate failedPurchaseWithError:transaction.error.localizedDescription];
    }
    
    self.currentTransaction = transaction;
}
// 14.交易结束,当交易结束后还要去appstore上验证支付信息是否都正确,只有所有都正确后,我们就可以给用户方法我们的虚拟物品了。




-(NSString * )environmentForReceipt:(NSString * )str
{
    str= [str stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
    
    str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    str = [str stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    
    str=[str stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    str=[str stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    
    NSArray * arr=[str componentsSeparatedByString:@";"];
    
    //存储收据环境的变量
    NSString * environment=arr[2];
    return environment;
}


@end
