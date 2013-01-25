//
//  CameraViewController.h
//  Camera Framework App
//
//  Created by Bobby Ren on 1/24/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CaptureSessionManager.h"

@interface CameraViewController : UIViewController

// CaptureSessionManager
@property (assign) BOOL isCapturing;
@property (retain) CaptureSessionManager *captureManager;

// camera controls
@property (nonatomic, weak) IBOutlet UIButton * buttonTakePicture;
@property (nonatomic, weak) IBOutlet UIButton * buttonFlash;
@property (nonatomic, weak) IBOutlet UIButton * buttonDevice;

-(IBAction)toggleFlashMode:(id)sender;
-(IBAction)toggleCameraDevice:(id)sender;
-(IBAction)didClickTakePicture:(id)sender;

@end
