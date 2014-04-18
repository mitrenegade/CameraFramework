//
//  PixPreviewController.m
//  Stixx
//
//  Created by Bobby Ren on 6/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PixPreviewController.h"

@implementation PixPreviewController

@synthesize buttonOK, buttonCancel, imageView;
@synthesize delegate;
@synthesize activityIndicatorLarge;

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

    StickerPanelViewController * controller = [[StickerPanelViewController alloc] init];
    [controller setDelegate:self];
    [self.view addSubview:controller.view];
    
    CGRect frameOff = self.view.frame;
    frameOff.origin.y += self.view.frame.size.height;
    [controller.view setFrame:frameOff];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)initWithImage:(UIImage*)newImage {
    [imageView setImage:newImage];
}

-(IBAction)didClickOK:(id)sender {
    NSLog(@"PixPreview did click ok **************");
    if (!activityIndicatorLarge) {
        activityIndicatorLarge = [[LoadingAnimationView alloc] initWithFrame:CGRectMake(115, 170, 90, 90)];
        [self.view addSubview:activityIndicatorLarge];
    }
    [activityIndicatorLarge startAnimating];
//    [self.navigationController popViewControllerAnimated:NO]; // close self
    [delegate performSelector:@selector(didConfirmPix) withObject:delegate afterDelay:0];
    //[delegate didConfirmPix];
}

-(IBAction)didClickBackButton:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

-(void)startActivityIndicatorLarge {
    [activityIndicatorLarge startAnimating];
}
-(void)stopActivityIndicatorLarge {
    [activityIndicatorLarge stopAnimating];
}
@end
