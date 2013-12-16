//
//  LoginViewController.m
//  Camera Framework App
//
//  Created by Bobby Ren on 1/5/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import "LoginViewController.h"
#import <Parse/Parse.h>
#import "SignupViewController.h"
#import "AppDelegate.h"
#import "UIAlertView+MKBlockAdditions.h"
#import "EmailLoginViewController.h"
#import "AWSHelper.h"
#import "Constants.h"
#import "JSONKit.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

@synthesize userInfoNew;

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

-(IBAction)didClickFacebookLogin:(id)sender {
    NSLog(@"Clicked facebook login");
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

            // can create UserInfo here if necessary
            [[UIAlertView alertViewWithTitle:@"User does not exist!" message:@"Would you like to create one?" cancelButtonTitle:@"Cancel" otherButtonTitles:[NSArray arrayWithObject:@"Create user"] onDismiss:^(int buttonIndex) {
                if (buttonIndex == 0) {
                    // create userInfo
                    [self createNewFacebookUserInfo:user];
                }
            } onCancel:^{
                NSLog(@"Ok, cancelling new user");
                [user deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        // do nothing, show menu again
                    }
                }];
            }] show];
        } else {
            NSLog(@"User with facebook logged in!");
            [self didGetPFUser:user];
        }
    }];
}

-(IBAction)didClickTwitterLogin:(id)sender {
    NSLog(@"Clicked twitter login");
    [PFTwitterUtils logInWithBlock:^(PFUser *user, NSError *error) {
        if (!user) {
            if (!error) {
                NSLog(@"Uh oh. The user cancelled the Twitter login.");
            } else {
                NSLog(@"Uh oh. An error occurred: %@", error);
            }
        } else if (user.isNew) {
            NSLog(@"User with facebook signed up and logged in!");
            
            // can create UserInfo here if necessary
            [[UIAlertView alertViewWithTitle:@"User does not exist!" message:@"Would you like to create one?" cancelButtonTitle:@"Cancel" otherButtonTitles:[NSArray arrayWithObject:@"Create user"] onDismiss:^(int buttonIndex) {
                if (buttonIndex == 0) {
                    // create userInfo
                    [self createNewTwitterUserInfo:user];
                }
            } onCancel:^{
                NSLog(@"Ok, cancelling new user");
                [user deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        // do nothing, show menu again
                    }
                }];
            }] show];
        } else {
            NSLog(@"User with twitter logged in!");
            [self didGetPFUser:user];
        }
    }];
}

-(IBAction)didClickEmailLogin:(id)sender {
    NSLog(@"Clicked email login");
    EmailLoginViewController * controller = [[EmailLoginViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

-(IBAction)didClickSignup:(id)sender {
    NSLog(@"Clicked signup");
    /*
    SignupViewController * controller = [[SignupViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
     */
}

-(void)didGetPFUser:(PFUser*)user {
    AppDelegate * appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

    // find UserInfo from parse; if not exist, extract from facebook or twitter
    [UserInfo GetUserInfoForPFUser:user withBlock:^(UserInfo * userInfo, NSError * error) {
        if (error) {
            NSLog(@"LoginViewController GetUserInfoForPFUser error: %@", error);
            // do nothing, show menu again
        }
        else {
            if (userInfo) {
                [appDelegate didLoginPFUser:user withUserInfo:userInfo];
            }
            else {
                // if facebook user, get facebook info
                if ([PFFacebookUtils isLinkedWithUser:user])
                    [self createNewFacebookUserInfo:user];
                else if ([PFTwitterUtils isLinkedWithUser:user])
                    [self createNewTwitterUserInfo:user];
            }
        }
    }];
}

-(void)createNewFacebookUserInfo:(PFUser*)user {
    NSLog(@"Populating userInfo");
    userInfoNew = [[UserInfo alloc] init];
    
    NSString *requestPath = @"me/?fields=name,picture";
    
    // Send request to Facebook
    PF_FBRequest *request = [PF_FBRequest requestForGraphPath:requestPath];
    [request startWithCompletionHandler:^(PF_FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            NSDictionary *userData = (NSDictionary *)result; // The result is a dictionary
            
            NSLog(@"Facebook info received: %@", result);
            
            NSString *facebookId = userData[@"id"];
            NSString *name = userData[@"name"];
            NSDictionary * photo = userData[@"picture"];
            NSString * photoURL = photo[@"data"][@"url"];
            
            userInfoNew.username = name;
            userInfoNew.pfUser = user;
            userInfoNew.pfUserID = user.objectId;
            userInfoNew.photoURL = nil;
            userInfoNew.photo = nil;
            
            // download photo and save to aws
            [userInfoNew savePhotoToAWSWithURL:photoURL withNameKey:userInfoNew.username withBlock:^(BOOL saved) {
                if (saved) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMyUserInfoDidChangeNotification object:self userInfo:nil];
                }
            }];
            
            // save userInfo in parallel
            [[userInfoNew toPFObject] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    AppDelegate * appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                    [appDelegate didLoginPFUser:user withUserInfo:userInfoNew];
                }
                else {
                    NSLog(@"Could not save userInfo! Error: %@", error);
                }
            }];
        }
    }];
}

-(void)createNewTwitterUserInfo:(PFUser*)user {
    NSLog(@"Populating userInfo");
    userInfoNew = [[UserInfo alloc] init];

    // authenticate
    NSURL *verify = [NSURL URLWithString:@"https://api.twitter.com/1/account/verify_credentials.json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:verify];
    [[PFTwitterUtils twitter] signRequest:request];
    NSURLResponse *response = nil;
    NSError * error;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];

    NSError *parseError;
    JSONDecoder * decoder = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
    id parsedData = [decoder objectWithData:data error:&parseError];
    NSLog(@"Decoded json: %@", parsedData);

    NSString *twitterID = parsedData[@"id"];
    NSString *name = parsedData[@"name"];
    NSString * screenname = parsedData[@"screen_name"];
    NSString * photoURL = parsedData[@"profile_image_url"];
    
    userInfoNew.username = screenname;
    userInfoNew.pfUser = user;
    userInfoNew.pfUserID = user.objectId;
    userInfoNew.photoURL = nil;
    userInfoNew.photo = nil;
    
    // download photo and save to aws
    [userInfoNew savePhotoToAWSWithURL:photoURL withNameKey:userInfoNew.username withBlock:^(BOOL saved) {
        if (saved) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kMyUserInfoDidChangeNotification object:self userInfo:nil];
        }
    }];
    
    // save userInfo in parallel
    [[userInfoNew toPFObject] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            AppDelegate * appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            [appDelegate didLoginPFUser:user withUserInfo:userInfoNew];
        }
        else {
            NSLog(@"Could not save userInfo! Error: %@", error);
        }
    }];
}
@end
