//
//  StoreKitHelper.h
//  Camera Framework App
//
//  Created by Bobby Ren on 2/13/14.
//  Copyright (c) 2014 Neroh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

UIKIT_EXTERN NSString *const StoreKitHelperProductPurchasedNotification;
UIKIT_EXTERN NSString *const StoreKitHelperProductFailedNotification;
UIKIT_EXTERN NSString *const StoreKitHelperProductRestoredNotification;
UIKIT_EXTERN NSString *const StoreKitHelperProductRestoreFailedNotification;

#define PRODUCT_ID_POSTAGE @"com.neroh.heartfx.postage"
#define PRODUCT_ID_LICENSE @"com.neroh.heartfx.license"

typedef void (^RequestProductsCompletionHandler)(BOOL success, NSArray * products);

@interface StoreKitHelper : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

+ (StoreKitHelper *)sharedInstance;
+(BOOL)hasPostage;
+(BOOL)hasLicense;
+(SKProduct *)postage;
+(SKProduct *)license;
+(int)deductPostage;
+(int)postageCount;

// load/display
- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers;
- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler;

// purchase
- (void)buyProduct:(SKProduct *)product;
- (int)purchaseCount:(NSString *)productIdentifier;
- (void)restoreCompletedTransactions;

// quick accessors for products
-(SKProduct *)postage;
-(SKProduct *)license;
@end
