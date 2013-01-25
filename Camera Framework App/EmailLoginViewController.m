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
    inputFields = [[NSMutableArray alloc] initWithCapacity:2];
    for (int i=0; i<2; i++)
        [inputFields addObject:[NSNull null]];
    [tableView.layer setCornerRadius:10];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

-(float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell * cell = (UITableViewCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.numberOfLines = 1;
        [cell setBackgroundColor:[UIColor clearColor]];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
    }
    
    // Configure the cell...
    int index = [indexPath row];
    for (UIView * subview in cell.subviews)
        [subview removeFromSuperview];
    [cell addSubview:[self viewForItemAtIndex:index]];
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 2;
}

-(UIView*)viewForItemAtIndex:(int)index {
    if (index == 0) {
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 110, 54)];
        [label setText:@"Name or Email"];
        [label setFont:[UIFont boldSystemFontOfSize:15]];
        UITextField * inputField = [[UITextField alloc] initWithFrame:CGRectMake(115, 0, 170, 54)];
        [inputField setTextAlignment:NSTextAlignmentLeft];
        inputField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        [inputField setPlaceholder:@"example@example.com"];
        [inputField setDelegate:self];
        UIView * view = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 300, 54)];
        [view addSubview:label];
        [view addSubview:inputField];
        
        [inputFields replaceObjectAtIndex:index withObject:inputField];
        return view;
    }
    else if (index == 1) {
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 54)];
        [label setText:@"Password"];
        [label setFont:[UIFont boldSystemFontOfSize:15]];
        UITextField * inputField = [[UITextField alloc] initWithFrame:CGRectMake(115, 0, 170, 54)];
        [inputField setTextAlignment:NSTextAlignmentLeft];
        [inputField setDelegate:self];
        [inputField setSecureTextEntry:YES];
        [inputField setPlaceholder:@"Your password"];
        inputField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        UIView * view = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 300, 54)];
        [view addSubview:label];
        [view addSubview:inputField];
        
        [inputFields replaceObjectAtIndex:index withObject:inputField];
        return view;
    }
    return nil;
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    // text field must also have delegate set as file's owner
	[textField resignFirstResponder];
    if (textField == [inputFields objectAtIndex:0])
        [[inputFields objectAtIndex:1] becomeFirstResponder];
	return YES;
}

-(IBAction)didClickLogin:(id)sender
{
    UITextField * login = [inputFields objectAtIndex:0];
    UITextField * password = [inputFields objectAtIndex:1];
    [login resignFirstResponder];
	[password resignFirstResponder];
    
    if ([[login text] length]==0) {
        [[[UIAlertView alloc] initWithTitle:@"Please enter a username or email." message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        return;
    }
    if ([[password text] length]==0) {
        [[[UIAlertView alloc] initWithTitle:@"Please enter a password." message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        return;
    }
    
    NSLog(@"Using login %@ and password %@", [login text], [password text]);
    
    //[k loginWithNameOrEmailWithLoginName:[login text]];
    [self tryLogin:[login text] password:[password text]];
}

#pragma mark ParseHelper login
-(void)tryLogin:(NSString*)username password:(NSString*)password {
    [ParseHelper ParseHelper_loginUsername:username password:password withBlock:^(PFUser * user, NSError * error) {
        if (user) {
            // do something
        }
        else {
            NSLog(@"Invalid login! What you entered was neither a valid username or email!");
            [[[UIAlertView alloc] initWithTitle:@"Your login was invalid." message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        }
    }];
}

@end
