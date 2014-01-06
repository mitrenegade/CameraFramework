//
//  ShareViewController.m
//  Camera Framework App
//
//  Created by Bobby Ren on 3/4/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import "ShareViewController.h"
#import "AppDelegate.h"
#import "UIAlertView+MKBlockAdditions.h"
#import "Appirater.h"

@interface ShareViewController ()

@end

@implementation ShareViewController

@synthesize buttonFacebook, buttonInstagram, buttonTwitter, buttonContacts;
@synthesize delegate;

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
    // check for defaults
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:@"FirstTimeSaveMessageDone"] == nil) {
        [[UIAlertView alertViewWithTitle:@"Earn a bonus!" message:@"Share three times on Facebook, Twitter or Instagram to gain a Mystery Pack!" cancelButtonTitle:@"Go!" otherButtonTitles:nil onDismiss:^(int buttonIndex) {
        } onCancel:^{
            [userDefaults setObject:[NSNumber numberWithBool:YES] forKey:@"FirstTimeSaveMessageDone"];
        }] show];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)didClickClose:(id)sender {
    //[self dismissModalViewControllerAnimated:YES];
    [Appirater userDidSignificantEvent:YES];
    [delegate closeShareView];
}

-(IBAction)didClickShare:(id)sender {
    UIButton * button = (UIButton*)sender;
    if (button == buttonFacebook) {
        [delegate didClickFacebookShare];
    }
    else if (button == buttonInstagram) {
        [delegate didClickInstagramShare];
    }
    else if (button == buttonTwitter) {
        [delegate didClickTwitterShare];
    }
    else if (button == buttonContacts) {
        [delegate didClickContactsShare];
    }
}


@end
