//
//  FBHelper.m
//  Camera Framework App
//
//  Created by Bobby Ren on 2/15/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import "FBHelper.h"
#import <FacebookSDK/FacebookSDK.h>

@implementation FBHelper

@synthesize delegate;

#pragma mark Facebook calls
- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
{
    switch (state) {
        case FBSessionStateOpen: {
            /*
             UIViewController *topViewController =
             [self.navController topViewController];
             if ([[topViewController modalViewController]
             isKindOfClass:[SCLoginViewController class]]) {
             [topViewController dismissModalViewControllerAnimated:YES];
             }
             */
            NSLog(@"New state: %d", state);
            if ([delegate respondsToSelector:@selector(didOpenSession)]) {
                [delegate didOpenSession];
            }
        }
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            // Once the user has logged in, we want them to
            // be looking at the root view.
            /*
             [self.navController popToRootViewControllerAnimated:NO];
             */
            
            [FBSession.activeSession closeAndClearTokenInformation];
            /*
             [self showLoginView];
             */
            NSLog(@"New state: %d", state);
            break;
        default:
            break;
    }
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:error.localizedDescription
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        [delegate didFailOpen];
    }
}

-(void)openSession
{
    // first request read permissions
    [FBSession openActiveSessionWithReadPermissions:nil
                                       allowLoginUI:YES
                                  completionHandler:
     ^(FBSession *session,
       FBSessionState state, NSError *error) {
         if (error) {
             NSLog(@"Error: code %d", error.code);
         }
         else {
             [self sessionStateChanged:session state:state error:error];
         }
     }];
}

-(void)requestPublish {
    NSArray * permissions = [NSArray arrayWithObject:@"publish_stream"];
    [[FBSession activeSession] requestNewPublishPermissions:permissions defaultAudience:FBSessionDefaultAudienceEveryone completionHandler:^(FBSession *session, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
            if (error.code == 2) {
                // this happens if app is not deleted but permissions are revoked
                // first time we request publish permissions right after requesting read permissions, facebook is stupid.
                // try again with a delay
                //[self performSelector:@selector(requestPublish) withObject:nil afterDelay:1]; -> causes exception error
                
                // send user a message to try again
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle:@"Error!"
                                          message:@"We couldn't connect to facebook...please try again!"
                                          delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
                [alertView show];
                [delegate didFailOpen];
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(didGetPublishPermissions)])
                [delegate didGetPublishPermissions];
        }
    }];
}

-(void)logout {
    [FBSession.activeSession closeAndClearTokenInformation];
}
@end
