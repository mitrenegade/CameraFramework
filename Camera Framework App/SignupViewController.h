//
//  SignupViewController.h
//  Camera Framework App
//
//  Created by Bobby Ren on 1/4/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//
#if 0

#import <UIKit/UIKit.h>
#import "UserInfo.h"

@interface SignupViewController : UIViewController <UINavigationControllerDelegate>

@property (nonatomic, strong) UserInfo * userInfo;

-(IBAction)didClickFacebookSignup:(id)sender;
-(IBAction)didClickTwitterSignup:(id)sender;
-(IBAction)didClickEmailSignup:(id)sender;

@end
#endif
