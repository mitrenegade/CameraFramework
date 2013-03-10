//
//  AppDelegate.h
//  Camera Framework App
//
//  Created by Bobby Ren on 1/4/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "UserInfo.h"
#import "MBProgressHUD.h"
#import <FacebookSDK/FacebookSDK.h>
#import "Instagram.h"

static NSString* const kMyUserInfoDidChangeNotification= @"kMyUserInfoDidChangeNotification";
static NSString* const kInstagramAuthSuccessNotification= @"kInstagramAuthSuccessNotification";

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, IGSessionDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UITabBarController *tabBarController;

@property (strong, atomic) UserInfo * myUserInfo;

@property (nonatomic, strong) Instagram * instagram;

-(void)didLoginPFUser:(PFUser *)user withUserInfo:(UserInfo*)userInfo;

-(void)instagramAuth;
@end
