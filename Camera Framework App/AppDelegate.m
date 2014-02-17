//
//  AppDelegate.m
//  Camera Framework App
//
//  Created by Bobby Ren on 1/4/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
#import "ParseHelper.h"
#import "PreviewController.h"
#import "ProfileViewController.h"
#import "CameraViewController.h"
#import "Constants.h"
#import "Flurry.h"
#import <Crashlytics/Crashlytics.h>
#import "UIAlertView+MKBlockAdditions.h"
#import "Appirater.h"

@implementation AppDelegate

@synthesize myUserInfo;
//@synthesize instagram;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [application setStatusBarStyle:UIStatusBarStyleDefault];

    // initialize parse
    [Parse setApplicationId:PARSE_APP_ID
                  clientKey:PARSE_CLIENT_ID];

    // allow current user
    [PFUser enableAutomaticUser];
    [PFAnonymousUtils logInWithBlock:^(PFUser *user, NSError *error) {
        if (error) {
            NSLog(@"Anonymous login failed.");
        } else {
            NSLog(@"Anonymous user logged in.");
            NSLog(@"Current user: %@", [PFUser currentUser]);
        }
    }];

    // connect to facebook via parse
    //[PFFacebookUtils initializeWithApplicationId:FACEBOOK_APP_ID];
    [PFFacebookUtils initializeFacebook];
    
    // enable twitter
    [PFTwitterUtils initializeWithConsumerKey:TWITTER_APP_CONSUMERKEY consumerSecret:TWITTER_APP_CONSUMERSECRET];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // flurry
	NSString *version =  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    [Flurry setAppVersion:version];
    [Flurry startSession:FLURRY_APP_KEY];
    
    // appirater
    [Appirater appLaunched];

    // crashlytics
    [Crashlytics startWithAPIKey:@"747b4305662b69b595ac36f88f9c2abe54885ba3"];
    
    // try login process
#if USE_LOGIN
    PFUser * currentUser = [PFUser currentUser];
    if (currentUser) {
        NSLog(@"Current PFUser exists.");
        MBProgressHUD * progress = [MBProgressHUD showHUDAddedTo:self.window animated:YES];
        progress.labelText = @"Welcome back..";
        [progress show:YES];
        
        // after login with a valid user, always get myUserInfo from parse
        [UserInfo GetUserInfoForPFUser:currentUser withBlock:^(UserInfo * parseUserInfo, NSError * error) {
            if (error) {
                NSLog(@"GetUserInfo for PFUser received error: %@", error);
                progress.labelText = @"Could not login!";
                [progress hide:YES afterDelay:2];

                // create preview controller if not logged in
                PreviewController * previewController = [[PreviewController alloc] init];
                self.window.rootViewController = previewController;
                [self.window makeKeyAndVisible];
            }
            else {
                if (!parseUserInfo) {
                    // userInfo doesn't exist, must create by doing a cached login
                    // create preview controller if not logged in
                    PreviewController * previewController = [[PreviewController alloc] init];
                    self.window.rootViewController = previewController;
                    [self.window makeKeyAndVisible];
                }
                else {
                    [self.window makeKeyAndVisible];
                    [self didLoginPFUser:currentUser withUserInfo:parseUserInfo];
                }
                [progress hide:YES];
            }
        }];
    }
    else {
        NSLog(@"No cached pfuser!");
        // create preview controller if not logged in
        PreviewController * previewController = [[PreviewController alloc] init];
        self.window.rootViewController = previewController;
        [self.window makeKeyAndVisible];
    }
#else
    [self continueInitForQuickStickr];
#endif
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [Appirater appEnteredForeground:YES];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    //[FBSession.activeSession handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

/*
-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSLog(@"access token: %@", self.instagram.accessToken);
    return [self.instagram handleOpenURL:url];
}
*/

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
#if USE_LOGIN
    return [PFFacebookUtils handleOpenURL:url];
#else
    NSLog(@"URL Scheme: %@", url.scheme);
    if ([url.scheme rangeOfString:FACEBOOK_APP_ID].location != NSNotFound) {
        NSLog(@"Facebook scheme redirect!");
        return [FBSession.activeSession handleOpenURL:url];
    }
    else if ([url.scheme rangeOfString:INSTAGRAM_CLIENT_ID].location != NSNotFound) {
        /*
        NSLog(@"Instagram scheme redirect!");
        NSLog(@"access token: %@", self.instagram.accessToken);
        return [self.instagram handleOpenURL:url];
         */
    }
#endif
}

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
}
*/

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
}
*/

-(void)didLoginPFUser:(PFUser *)user withUserInfo:(UserInfo*)userInfo{
    // todo: can get UserInfo here
    
    // dismiss login process
    [self.window.rootViewController dismissModalViewControllerAnimated:YES];
    self.myUserInfo = userInfo;

    [self continueInit];
}

-(void)continueInit {
    CameraViewController *cameraController = [[CameraViewController alloc] initWithNibName:@"CameraViewController" bundle:nil];
    ProfileViewController * profileController = [[ProfileViewController alloc] init];
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = @[cameraController, profileController];
    
    self.window.rootViewController = self.tabBarController;
}

-(void)continueInitForQuickStickr {
    [self.window makeKeyAndVisible];
    CameraViewController *controller = [[CameraViewController alloc] initWithNibName:@"CameraViewController" bundle:nil];
    self.window.rootViewController = controller;

    // initialize and listen for products
    [StoreKitHelper sharedInstance];
}

-(void)incrementMysteryPackCount {
    [UIAlertView alertViewWithTitle:@"Sharing complete" message:nil];
}

#if 0
// instagram auth not needed since we use app through document handler
/*
-(void)instagramAuth {
    self.instagram = [[Instagram alloc] initWithClientId:INSTAGRAM_CLIENT_ID
                                                delegate:nil];
    // here i can set accessToken received on previous login
    self.instagram.accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"accessToken"];
    self.instagram.sessionDelegate = self;
    NSLog(@"access token: %@", self.instagram.accessToken);
    if ([self.instagram isSessionValid]) {
        NSLog(@"Has valid instagram!");
        [[NSNotificationCenter defaultCenter] postNotificationName:kInstagramAuthSuccessNotification object:nil];
    } else {
        [self.instagram authorize:[NSArray arrayWithObjects:@"comments", @"likes", nil]];
    }
}

#pragma - IGSessionDelegate

-(void)igDidLogin {
    NSLog(@"Instagram did login");
    // here i can store accessToken
    [[NSUserDefaults standardUserDefaults] setObject:self.instagram.accessToken forKey:@"accessToken"];
	[[NSUserDefaults standardUserDefaults] synchronize];

    [[NSNotificationCenter defaultCenter] postNotificationName:kInstagramAuthSuccessNotification object:nil];
}

-(void)igDidNotLogin:(BOOL)cancelled {
    NSLog(@"Instagram did not login");
    NSString* message = nil;
    if (cancelled) {
        message = @"Access cancelled!";
    } else {
        message = @"Access denied!";
    }
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
    [alertView show];
}

-(void)igDidLogout {
    NSLog(@"Instagram did logout");
    // remove the accessToken
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"accessToken"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)igSessionInvalidated {
    NSLog(@"Instagram session was invalidated");
}
 */
#endif

@end
