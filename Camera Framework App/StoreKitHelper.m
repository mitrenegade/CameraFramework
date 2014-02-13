//
//  StoreKitHelper.m
//  Camera Framework App
//
//  Created by Bobby Ren on 2/13/14.
//  Copyright (c) 2014 Neroh. All rights reserved.
//

#import "StoreKitHelper.h"

@interface StoreKitHelper () <SKProductsRequestDelegate>
@end
NSString *const StoreKitHelperProductPurchasedNotification = @"StoreKitHelperProductPurchasedNotification";
NSString *const StoreKitHelperProductFailedNotification = @"StoreKitHelperProductFailedNotification";

@implementation StoreKitHelper
{
    // 3
    SKProductsRequest * _productsRequest;
    // 4
    RequestProductsCompletionHandler _completionHandler;
    NSSet * _productIdentifiers;
    NSMutableDictionary * _purchasedProducts;
    NSMutableDictionary * _products;
}

+ (StoreKitHelper *)sharedInstance {
    static dispatch_once_t once;
    static StoreKitHelper * sharedInstance;
    dispatch_once(&once, ^{
        NSSet * productIdentifiers = [NSSet setWithObjects:
                                      PRODUCT_ID_POSTAGE,
                                      PRODUCT_ID_LICENSE,
                                      nil];
        sharedInstance = [[self alloc] initWithProductIdentifiers:productIdentifiers];
    });
    return sharedInstance;
}

+(SKProduct *)postage {
    return [[StoreKitHelper sharedInstance] postage];
}

+(SKProduct *)license {
    return [[StoreKitHelper sharedInstance] license];
}

+(int)postageCount {
    return [[StoreKitHelper sharedInstance] postageCount];
}

+(BOOL)hasPostage {
    BOOL hasPostage = [[StoreKitHelper sharedInstance] purchaseCount:PRODUCT_ID_POSTAGE] > 0;
    NSLog(@"Has postage: %d", hasPostage);
    return hasPostage;
}

+(BOOL)hasLicense {
    BOOL hasLicense = [[StoreKitHelper sharedInstance] purchaseCount:PRODUCT_ID_LICENSE] > 0;
    NSLog(@"Has license: %d", hasLicense);
    return hasLicense;
}

+(int)deductPostage {
    // deducts and returns count
    // returns -1 if invalid
    return [[StoreKitHelper sharedInstance] consume:PRODUCT_ID_POSTAGE];
}
- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers {

    if ((self = [super init])) {

        // Store product identifiers
        _productIdentifiers = productIdentifiers;

        // Check for previously purchased products
        _purchasedProducts = [NSMutableDictionary dictionary];
        _products = [NSMutableDictionary dictionary];
        for (NSString * productIdentifier in _productIdentifiers) {
            int purchaseCount = [[NSUserDefaults standardUserDefaults] integerForKey:productIdentifier];
            [_purchasedProducts setObject:@(purchaseCount) forKey:productIdentifier];
            NSLog(@"Previously purchased: %@", productIdentifier);
        }

        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];

        [self requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
            NSLog(@"Received %d products", [products count]);
        }];
    }
    return self;
}

- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler {

    // 1
    _completionHandler = [completionHandler copy];

    // 2
    _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers];
    _productsRequest.delegate = self;
    [_productsRequest start];
    
}

- (int)purchaseCount:(NSString *)productIdentifier {
    return [[_purchasedProducts objectForKey:productIdentifier] intValue];
}

- (void)buyProduct:(SKProduct *)product {

    NSLog(@"Buying %@...", product.productIdentifier);

    SKPayment * payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
}

- (void)restoreCompletedTransactions {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

-(SKProduct *)postage {
    return _products[PRODUCT_ID_POSTAGE];
}

-(SKProduct *)license {
    return _products[PRODUCT_ID_LICENSE];
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {

    NSLog(@"Loaded list of products...");
    _productsRequest = nil;

    NSArray * skProducts = response.products;
    for (SKProduct * skProduct in skProducts) {
        NSLog(@"Found product: %@ %@ %0.2f",
              skProduct.productIdentifier,
              skProduct.localizedTitle,
              skProduct.price.floatValue);

        // add to our list
        [_products setObject:skProduct forKey:skProduct.productIdentifier];
    }

    _completionHandler(YES, skProducts);
    _completionHandler = nil;

}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {

    NSLog(@"Failed to load list of products. error: %@", error);
    _productsRequest = nil;

    _completionHandler(NO, nil);
    _completionHandler = nil;
    
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction * transaction in transactions) {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    };
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"completeTransaction...");

    [self provideContentForProductIdentifier:transaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"restoreTransaction...");

    [self provideContentForProductIdentifier:transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {

    NSLog(@"failedTransaction...");
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        NSLog(@"Transaction error: %@", transaction.error.localizedDescription);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:StoreKitHelperProductFailedNotification object:nil userInfo:@{@"error":transaction.error}];

    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void)provideContentForProductIdentifier:(NSString *)productIdentifier {

    int count = 0;
    if ([productIdentifier isEqualToString:PRODUCT_ID_POSTAGE]) {
        count = [_purchasedProducts[productIdentifier] intValue] + 1;
    }
    else {
        count = 1;
    }
    _purchasedProducts[productIdentifier] = @(count);
    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:StoreKitHelperProductPurchasedNotification object:productIdentifier userInfo:nil];
    
}

-(int)consume:(NSString *)productIdentifier {
    if (![productIdentifier isEqualToString:PRODUCT_ID_POSTAGE])
        return -1;

    int count = [_purchasedProducts[productIdentifier] intValue];
    if (count < 0)
        return -1;

    count = count - 1;
    _purchasedProducts[productIdentifier] = @(count);
    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];

    return count;
}

-(int)postageCount {
    int count = [_purchasedProducts[PRODUCT_ID_POSTAGE] intValue];
    return count;
}
@end
