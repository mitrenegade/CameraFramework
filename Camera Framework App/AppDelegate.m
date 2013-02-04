//
//  AppDelegate.m
//  Camera Framework App
//
//  Created by Bobby Ren on 1/4/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import "AppDelegate.h"
#import "FirstViewController.h"
#import "SecondViewController.h"
#import <Parse/Parse.h>
#import "ParseHelper.h"
#import "PreviewController.h"
#import "ProfileViewController.h"
#import "CameraViewController.h"
#import "Constants.h"

@implementation AppDelegate

@synthesize myUserInfo;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // initialize parse
    [Parse setApplicationId:PARSE_APP_ID
                  clientKey:PARSE_CLIENT_ID];
    
    // connect to facebook via parse
    [PFFacebookUtils initializeWithApplicationId:FACEBOOK_APP_ID];
    
    // enable twitter
    [PFTwitterUtils initializeWithConsumerKey:TWITTER_APP_CONSUMERKEY consumerSecret:TWITTER_APP_CONSUMERSECRET];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
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
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [PFFacebookUtils handleOpenURL:url];
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
    CameraViewController *cameraController = [[CameraViewController alloc] initWithNibName:@"CameraViewController" bundle:nil];
    self.window.rootViewController = cameraController;
    [self.window makeKeyAndVisible];
}
@end
