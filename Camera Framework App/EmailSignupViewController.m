//
//  EmailSignupViewController.m
//  Camera Framework App
//
//  Created by Bobby Ren on 1/5/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import "EmailSignupViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface EmailSignupViewController ()

@end

@implementation EmailSignupViewController

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
    [tableView.layer setCornerRadius:10];
    //inputViews = [[NSMutableDictionary alloc] init];
    inputFields = [[NSMutableArray alloc] initWithCapacity:5];
    for (int i=0; i<5; i++)
        [inputFields addObject:[NSNull null]];
    didChangePhoto = NO;
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
    return 4;
}

-(UIView*)viewForItemAtIndex:(int)index {
    //if ([inputViews objectForKey:[NSNumber numberWithInt:index]])
    //    return [inputViews objectForKey:[NSNumber numberWithInt:index]];
    
    if (index == 0) {
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 54)];
        [label setText:@"Email"];
        [label setFont:[UIFont boldSystemFontOfSize:15]];
        UITextField * inputField = [[UITextField alloc] initWithFrame:CGRectMake(85, 0, 200, 54)];
        [inputField setPlaceholder:@"example@example.com"];
//        [inputField setTag:TAG_EMAIL];
        [inputField setTextAlignment:NSTextAlignmentLeft];
        [inputField setKeyboardType:UIKeyboardTypeEmailAddress];
        inputField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        [inputField setDelegate:self];
        UIView * view = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 300, 54)];
        [view addSubview:label];
        [view addSubview:inputField];
        
        //[inputViews setObject:view forKey:[NSNumber numberWithInt:index]];
        [inputFields replaceObjectAtIndex:index withObject:inputField];
        return view;
    }
    else if (index == 1) {
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 54)];
        [label setText:@"Username"];
        [label setFont:[UIFont boldSystemFontOfSize:15]];
        UITextField * inputField = [[UITextField alloc] initWithFrame:CGRectMake(85, 0, 200, 54)];
//        [inputField setTag:TAG_USERNAME];
        [inputField setTextAlignment:NSTextAlignmentLeft];
        [inputField setDelegate:self];
        [inputField setPlaceholder:@"Name or nickname"];
        inputField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        UIView * view = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 300, 54)];
        [view addSubview:label];
        [view addSubview:inputField];
        
        //[inputViews setObject:view forKey:[NSNumber numberWithInt:index]];
        [inputFields replaceObjectAtIndex:index withObject:inputField];
        return view;
    }
    if (index == 2) {
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 54)];
        [label setText:@"Password"];
        [label setFont:[UIFont boldSystemFontOfSize:15]];
        UITextField * inputField = [[UITextField alloc] initWithFrame:CGRectMake(85, 0, 200, 54)];
//        [inputField setTag:TAG_PASSWORD];
        [inputField setSecureTextEntry:YES];
        [inputField setTextAlignment:NSTextAlignmentLeft];
        [inputField setDelegate:self];
        [inputField setPlaceholder:@"Password"];
        inputField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        UIView * view = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 300, 54)];
        [view addSubview:label];
        [view addSubview:inputField];
        
        //[inputViews setObject:view forKey:[NSNumber numberWithInt:index]];
        [inputFields replaceObjectAtIndex:index withObject:inputField];
        return view;
    }
    if (index == 3) {
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 54)];
        [label setText:@"Picture"];
        [label setFont:[UIFont boldSystemFontOfSize:15]];
        UIButton * photoButton = [[UIButton alloc] initWithFrame:CGRectMake(85, 7, 40, 40)];
        [photoButton setImage:[UIImage imageNamed:@"graphic_login_picture"] forState:UIControlStateNormal];
        [photoButton addTarget:self action:@selector(didClickPhoto:) forControlEvents:UIControlEventTouchUpInside];
//        [photoButton setTag:TAG_PICTURE];
        [photoButton.layer setBorderWidth:2];
        UIView * view = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 300, 54)];
        [view addSubview:label];
        [view addSubview:photoButton];
        
        //[inputViews setObject:view forKey:[NSNumber numberWithInt:index]];
        [inputFields replaceObjectAtIndex:index withObject:photoButton];
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
    else if (textField == [inputFields objectAtIndex:1])
        [[inputFields objectAtIndex:2] becomeFirstResponder];
    
	return YES;
}

-(IBAction)didClickSignup:(id)sender
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
    /*
    [ParseHelper ParseHelper_loginUsername:username password:password withBlock:^(PFUser * user, NSError * error) {
        if (user) {
            // do something
        }
        else {
            NSLog(@"Invalid login! What you entered was neither a valid username or email!");
            [[[UIAlertView alloc] initWithTitle:@"Your login was invalid." message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        }
    }];
     */
}
@end
