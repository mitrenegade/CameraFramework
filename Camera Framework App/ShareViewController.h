//
//  ShareViewController.h
//  Camera Framework App
//
//  Created by Bobby Ren on 3/4/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>

@protocol ShareViewDelegate <NSObject>

-(void)didClickFacebookShare;
-(void)closeShareView;
-(void)didClickTwitterShare;
-(void)didClickInstagramShare;
-(void)didClickContactsShare;
@end

@interface ShareViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIButton * buttonInstagram;
@property (nonatomic, weak) IBOutlet UIButton * buttonFacebook;
@property (nonatomic, weak) IBOutlet UIButton * buttonTwitter;
@property (nonatomic, weak) IBOutlet UIButton * buttonContacts;
@property (nonatomic, weak) id delegate;

-(IBAction)didClickShare:(id)sender;
-(IBAction)didClickClose:(id)sender;
@end
