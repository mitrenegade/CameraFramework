//
//  SignupViewController.m
//  Camera Framework App
//
//  Created by Bobby Ren on 1/4/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//
// signup can be done through login

#if 0

#import "SignupViewController.h"
#import <Parse/Parse.h>
#import "AppDelegate.h"
#import "UIAlertView+MKBlockAdditions.h"
#import "EmailSignupViewController.h"

@interface SignupViewController ()

@end

@implementation SignupViewController
@synthesize userInfo;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)didClickFacebookSignup:(id)sender {
    NSLog(@"Clicked facebook signup");
    //    NSArray *permissions = @[ @"user_about_me", @"user_relationships", @"user_birthday", @"user_location"];
    NSArray *permissions = [[NSArray alloc] initWithObjects:
                            @"user_about_me",
                            @"user_photos",
                            @"publish_stream", // post to friend's stream
                            @"email",
                            nil];
    [PFFacebookUtils logInWithPermissions:permissions block:^(PFUser *user, NSError *error) {
        if (!user) {
            if (!error) {
                NSLog(@"Uh oh. The user cancelled the Facebook login.");
            } else {
                NSLog(@"Uh oh. An error occurred: %@", error);
            }
        } else if (user.isNew) {
            NSLog(@"User with facebook signed up and logged in!");
            [self didGetPFUser:user];
        } else {
            NSLog(@"User with facebook logged in!");
            // can create UserInfo here if necessary
            [[UIAlertView alertViewWithTitle:@"User already exists!" message:@"Would you like to continue with login?" cancelButtonTitle:@"Cancel" otherButtonTitles:[NSArray arrayWithObject:@"Login with this account"] onDismiss:^(int buttonIndex) {
                if (buttonIndex == 0) {
                    // login with existing user
                    [self didGetPFUser:user];
                }
            } onCancel:^{
                NSLog(@"Ok, cancelled");
                [PFUser logOut];
            }] show];
        }
    }];
}

-(IBAction)didClickTwitterSignup:(id)sender {
    NSLog(@"Clicked twitter signup");
    [PFTwitterUtils logInWithBlock:^(PFUser *user, NSError *error) {
        if (!user) {
            if (!error) {
                NSLog(@"Uh oh. The user cancelled the Twitter login.");
            } else {
                NSLog(@"Uh oh. An error occurred: %@", error);
            }
        } else if (user.isNew) {
            NSLog(@"User with Twitter signed up and logged in!");
            [self didGetPFUser:user];
        } else {
            NSLog(@"User with facebook logged in!");
            // can create UserInfo here if necessary
            [[UIAlertView alertViewWithTitle:@"User already exists!" message:@"Would you like to continue with login?" cancelButtonTitle:@"Cancel" otherButtonTitles:[NSArray arrayWithObject:@"Login with this account"] onDismiss:^(int buttonIndex) {
                if (buttonIndex == 0) {
                    // login with existing user
                    [self didGetPFUser:user];
                }
            } onCancel:^{
                NSLog(@"Ok, cancelled");
                [PFUser logOut];
            }] show];
        }
    }];
}

-(IBAction)didClickEmailSignup:(id)sender {
    NSLog(@"Clicked email signup");
    EmailSignupViewController * controller = [[EmailSignupViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

-(void)didGetPFUser:(PFUser*)user {
    AppDelegate * appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate didLoginPFUser:user withUserInfo:nil];
}

#endif

@end
