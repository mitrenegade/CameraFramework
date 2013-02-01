//
//  EmailSignupViewController.h
//  Camera Framework App
//
//  Created by Bobby Ren on 1/5/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EmailSignupViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UINavigationControllerDelegate>
{
    NSMutableArray * inputFields;
    BOOL didChangePhoto;
    NSString * prepopulatedEmail;
    
    IBOutlet UITableView * tableView;
    IBOutlet UIButton * buttonSignup;

    UIImagePickerController * camera;
}
-(IBAction)didClickSignup:(id)sender;
-(void)initializeWithEmail:(NSString*)email;
@end
