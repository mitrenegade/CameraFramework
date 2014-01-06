//
//  EmailLoginViewController.h
//  Camera Framework App
//
//  Created by Bobby Ren on 1/4/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParseHelper.h"
#import "UserInfo.h"

@protocol EmailLoginDelegate <NSObject>

-(void)didLoginPFUser:(PFUser *)user withUserInfo:(UserInfo*)userInfo;

@end

@interface EmailLoginViewController : UIViewController <UITextFieldDelegate, UINavigationControllerDelegate>
{
    IBOutlet UIButton * buttonLogin;
    __weak IBOutlet UITextField *inputUsername;
    __weak IBOutlet UITextField *inputPassword;
}
@property (nonatomic, weak) id delegate;

-(IBAction)didClickLogin:(id)sender;

@end
