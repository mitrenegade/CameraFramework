//
//  CameraViewController.m
//  Camera Framework App
//
//  Created by Bobby Ren on 1/24/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import "CameraViewController.h"

@interface CameraViewController ()

@end

@implementation CameraViewController
@synthesize captureManager;
@synthesize isCapturing;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"Camera", @"Camera");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self setCaptureManager:[[CaptureSessionManager alloc] init]];
    int flashMode = [captureManager initializeCamera];

	CGRect layerRect = [[[self view] layer] bounds];
	[[[self captureManager] previewLayer] setBounds:layerRect];
	[[[self captureManager] previewLayer] setPosition:CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect))];
    [[self.view layer] insertSublayer:[self.captureManager previewLayer] atIndex:0];

    // add a notification for completion of capture
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCaptureImage) name:kImageCapturedSuccessfully object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureImageDidFail:) name:kImageCaptureFailed object:nil];
    
    [self startCamera];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark CaptureSessionManager
-(void)startCamera {
    captureManager.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    [[captureManager captureSession] startRunning];
}

-(void)stopCamera {
    [[captureManager captureSession] stopRunning];
}

- (void)didCaptureImage
{
    //    [[self scanningLabel] setHidden:YES];
    UIImage * originalImage = [self.captureManager stillImage];
    
    // for AVCapture, it seems that the original image is 1936x2592 == 3:4. the iphone at 320x480 == 1728x2592
    // so there is content to the sides that isn't captured
    
    [self didTakePhoto:originalImage];
}

-(void)captureImageDidFail:(NSNotification*)notification {
    if ([[notification.userInfo objectForKey:@"code"] intValue] == -11801) {
        NSLog(@"Code=-11801 Cannot Complete Action UserInfo=0xe8b2480 {NSLocalizedRecoverySuggestion=Try again later., NSLocalizedDescription=Cannot Complete Action");
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Camera Error!" message:@"Image couldn't be captured" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alert show];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error != NULL) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"Image couldn't be saved" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
    }
    else {
    }
}

#pragma mark camera controls
-(IBAction)toggleFlashMode:(id)sender {
    int flashMode = [captureManager toggleFlash];
    
    // todo: [self updateCameraControlButtons:flashMode];
}

-(IBAction)toggleCameraDevice:(id)sender {
    [captureManager switchDevices];
}

-(IBAction)didClickTakePicture:(id)sender {
    if (isCapturing)
        return;
    
    [[self captureManager] captureStillImage];
    isCapturing = YES;
}

-(void)didTakePhoto:(UIImage*)originalPhoto{
    NSLog(@"Yay!");
    isCapturing = NO;
}

@end
