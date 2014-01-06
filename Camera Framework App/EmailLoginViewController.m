//
//  EmailLoginViewController.m
//  Camera Framework App
//
//  Created by Bobby Ren on 1/4/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import "EmailLoginViewController.h"
#import "ParseHelper.h"
#import <QuartzCore/QuartzCore.h>
#import "UserInfo.h"
#import "UIActionSheet+MKBlockAdditions.h"
#import "UIAlertView+MKBlockAdditions.h"
#import "AppDelegate.h"
#import "EmailSignupViewController.h"

@interface EmailLoginViewController ()

@end

@implementation EmailLoginViewController

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

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    // text field must also have delegate set as file's owner
	[textField resignFirstResponder];
    if (textField == inputUsername)
        [inputPassword becomeFirstResponder];
	return YES;
}

-(IBAction)didClickLogin:(id)sender
{
    [inputUsername resignFirstResponder];
	[inputPassword resignFirstResponder];
    
    if ([[inputUsername text] length]==0) {
        [[[UIAlertView alloc] initWithTitle:@"Please enter a username or email." message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        return;
    }
    if ([[inputPassword text] length]==0) {
        [[[UIAlertView alloc] initWithTitle:@"Please enter a password." message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        return;
    }
    
    NSLog(@"Using login %@ and password %@", [inputUsername text], [inputPassword text]);
    [self tryLogin:[inputUsername text] password:[inputPassword text]];
}

-(IBAction)didClickSignup:(id)sender {
    EmailSignupViewController * controller = [[EmailSignupViewController alloc] init];
    // prepopulate
    [controller initializeWithEmail:[inputUsername text]];
    [self.navigationController pushViewController:controller animated:YES];
}

-(void)tryLogin:(NSString*)username password:(NSString*)password {
    AppDelegate * appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [PFUser logInWithUsernameInBackground:username password:password block:^(PFUser * user, NSError * error) {
        if (user) {
            // user exists, get userinfo
            [UserInfo GetUserInfoForPFUser:user withBlock:^(UserInfo * userInfo, NSError * error) {
                if (error) {
                    NSLog(@"Could not find userInfo for user!");
                    // delete pfuser and go to email signup view to create a complete new user
                    [user deleteInBackground];
                    [self promptForSignup];
                }
                else {
                    // userinfo found, log in
                    [self.delegate didLoginPFUser:user withUserInfo:userInfo];
                }
            }];
        }
        else {
            [self promptForSignup];
        }
    }];
}

-(void)promptForSignup {
//    [UIActionSheet actionSheetWithTitle:@"No user found!" message:@"We could not load that user. Would you like to sign up?" buttons:[NSArray arrayWithObjects:@"OK", @"Try again", nil] showInView:self.view onDismiss:^(int buttonIndex) {
    [UIAlertView alertViewWithTitle:@"User not found" message:@"We could not find that user. Would you like to create the user?" cancelButtonTitle:@"No thanks" otherButtonTitles:[NSArray arrayWithObjects:@"Create user", nil] onDismiss:^(int buttonIndex) {

        // OK
        EmailSignupViewController * controller = [[EmailSignupViewController alloc] init];
        // prepopulate
        [controller initializeWithEmail:[inputUsername text]];
        [self.navigationController pushViewController:controller animated:YES];

    } onCancel:^{
        // cancel, do nothing
        inputUsername.text = @"";
        inputPassword.text = @"";
    }];
}

@end
