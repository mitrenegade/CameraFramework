//
//  LoginViewController.h
//  Camera Framework App
//
//  Created by Bobby Ren on 1/5/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserInfo.h"

@interface LoginViewController : UIViewController <UINavigationControllerDelegate>

@property (nonatomic, strong) UserInfo * userInfoNew;

-(IBAction)didClickFacebookLogin:(id)sender;
-(IBAction)didClickTwitterLogin:(id)sender;
-(IBAction)didClickEmailLogin:(id)sender;
-(IBAction)didClickSignup:(id)sender;
@end

