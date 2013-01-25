//
//  PreviewController.m
//  Camera Framework App
//
//  Created by Bobby Ren on 1/4/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import "PreviewController.h"
#import "LoginViewController.h"

@interface PreviewController ()

@end

@implementation PreviewController

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

-(IBAction)didClickNextButton:(id)sender {
    NSLog(@"You ready to log in?");
    LoginViewController * controller = [[LoginViewController alloc] init];
    if (self.navigationController)
        [self.navigationController pushViewController:controller animated:YES];
    else
        [self presentModalViewController:controller animated:YES];
}

@end
