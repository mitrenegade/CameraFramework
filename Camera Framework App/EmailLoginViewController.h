//
//  EmailLoginViewController.h
//  Camera Framework App
//
//  Created by Bobby Ren on 1/4/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EmailLoginViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UINavigationControllerDelegate>
{
    NSMutableArray * inputFields;
    
    IBOutlet UITableView * tableView;
    IBOutlet UIButton * buttonLogin;
}
-(IBAction)didClickLogin:(id)sender;

@end
