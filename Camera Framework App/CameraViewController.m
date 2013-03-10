//
//  CameraViewController.m
//  Camera Framework App
//
//  Created by Bobby Ren on 1/24/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import "CameraViewController.h"
#import "UIActionSheet+MKBlockAdditions.h"

@interface CameraViewController ()

@end

@implementation CameraViewController
@synthesize captureManager;
@synthesize isCapturing;
@synthesize buttonDevice, buttonFlash, buttonTakePicture;
@synthesize progress;

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

    [[self.view layer] insertSublayer:[self.captureManager previewLayer] atIndex:0];

    // add a notification for completion of capture
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCaptureImage) name:kImageCapturedSuccessfully object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureImageDidFail:) name:kImageCaptureFailed object:nil];
    
    [self startCamera];
    [self toggleFlashMode:0];
    [captureManager switchDevices]; // set to front facing
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // must set bounds here for resized views
    CGRect fullbounds = self.aperture.bounds;
	[[[self captureManager] previewLayer] setBounds:fullbounds];
	[[[self captureManager] previewLayer] setPosition:CGPointMake(CGRectGetMidX(fullbounds), CGRectGetMidY(fullbounds))];
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
    [self.progress hide:YES];
    
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
    switch (flashMode) {
        case AVCaptureFlashModeAuto:
            [buttonFlash setImage:[UIImage imageNamed:@"flash_auto.png"] forState:UIControlStateNormal];
            break;
        case AVCaptureFlashModeOn:
            [buttonFlash setImage:[UIImage imageNamed:@"flash.png"] forState:UIControlStateNormal];
            break;
        case AVCaptureFlashModeOff:
            [buttonFlash setImage:[UIImage imageNamed:@"flash_off.png"] forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
}

-(IBAction)toggleCameraDevice:(id)sender {
    [captureManager switchDevices];
}

-(IBAction)didClickTakePicture:(id)sender {
    if (isCapturing)
        return;
    
    self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.progress setLabelText:@"Capturing..."];
    
#if TARGET_IPHONE_SIMULATOR
    [self.progress hide:YES];
    [self didTakePhoto:[UIImage imageNamed:@"photo 2.JPG"]];
#else
    [[self captureManager] captureStillImage];
    isCapturing = YES;
#endif
}

-(void)didTakePhoto:(UIImage*)originalPhoto{
    NSLog(@"Yay!");
    isCapturing = NO;
    
    CGRect targetFrame = self.aperture.frame;
    float highResScale = 3;
    targetFrame.size.width *= highResScale;
    targetFrame.size.height *= highResScale;

    BOOL photoAlbumOpened = NO;
    
    UIImage *baseImage = originalPhoto;
    if (baseImage == nil) return;
    //UIImageOrientation or = [baseImage imageOrientation];
    // orientation 3 is normal (vertical) camera use, orientation 0 is landscape mode
    UIImageOrientation or = [UIDevice currentDevice].orientation;
    // 1 = vertical/normal
    // 2 = upside down
    // 3 = landscape left
    // 4 = landscape right
    BOOL landscape = (or >= 3 && !photoAlbumOpened);
    NSLog(@"or: %d photoAlbum: %d landscape %d", or, photoAlbumOpened, landscape);
    UIImage * final;
    UIImage * scaled;
    CGRect croppedFrame;
    
    float original_height = baseImage.size.height;
    float original_width = baseImage.size.width;
    
    // for AVCapture, there is no automatic rotation for landscape.
    // the raw image is 1936x2592 for high res photo setting == 358x480 or  //720x1280.
    // we want an image at 320x480, so we have to crop the SIDES
    
    // iphone 3.5 inch:
    // source image size is 2448x3264
    // image capture size is 320x407
    // scaled image is 305x407 if scaled by height
    // scaled image is 320 x 427 if scaled by width
    
    // iphone 5:
    // image capture size is is 320x495
    // scaled down, image is 371x495
    
    float scaled_width = original_width / original_height * targetFrame.size.height;
    float scaled_height = targetFrame.size.height;
    scaled = [originalPhoto resizedImage:CGSizeMake(scaled_width, scaled_height) interpolationQuality:kCGInterpolationHigh];
    float offsetX = (scaled_width - targetFrame.size.width) / 2;
    float offsetY = (scaled_height - targetFrame.size.height) / 2;
    
    if (offsetX < 0) {
        scaled_width = targetFrame.size.width;
        scaled_height = original_height / original_width * targetFrame.size.width;
        scaled = [originalPhoto resizedImage:CGSizeMake(scaled_width, scaled_height) interpolationQuality:kCGInterpolationHigh];
        offsetX = (scaled_width - targetFrame.size.width) / 2;
        offsetY = (scaled_height - targetFrame.size.height) / 2;
    }
    
    NSLog(@"originalWidth %f originalHeight %f", original_width, original_height);
    NSLog(@"scaledWidth %f scaledHeight %f offset %f %f", scaled_width, scaled_height, offsetX, offsetY);
    // target_height is smaller than scaled_height so we only take the middle
    //croppedFrame = CGRectMake(0, offset, 320, 480);
    croppedFrame = CGRectMake(offsetX, 0, targetFrame.size.width, targetFrame.size.height);
    final = [scaled croppedImage:croppedFrame];
    
    // result2 should be the exact same image as what the user sees in the camera view,
    // scaled down to the actual 320x480 size
    
    /*
    // rotate
    UIImage * result;
    if (or == 0 || or == 5)
        or = 1; // somehow invalid orientation. just treat as regular one
    if (photoAlbumOpened)
        result = result2;
    else
        result = [self rotateImage:result2 withCurrentOrientation:or];
    
    int target_width = self.view.frame.size.width;
    int target_height = self.view.frame.size.height;
    UIImage * cropped = nil;
    int minHeight = self.view.frame.origin.y + self.view.frame.size.height;
    int minWidth = self.view.frame.origin.x + self.view.frame.size.width;
    NSLog(@"target_width target_height %d %d result width result height %f %F", target_width, target_height, result.size.width, result.size.height);
    
    if ((or == 1 && result.size.height > minHeight) || (landscape && result.size.width > minWidth)) {
        // if resized image has height greater than the bottom of the crop frame
        CGRect targetFrame = [self.view frame];
        if (landscape) { // hack: loaded images from photo album will be or=0 even if they were taken normally
            int width = targetFrame.size.width;
            int height = targetFrame.size.height;
            int x = targetFrame.origin.y - (width - height)/2; // camera will take a picture that is taller than wide, but we display images that are wider than tall, so we offset the x by half that difference to keep the correct center and aspect ratio
            int y = self.view.frame.size.width - (targetFrame.origin.x + targetFrame.size.width);
            targetFrame = CGRectMake(x, y, width, height);
        }
        cropped = [result croppedImage:targetFrame];
        CGSize resultSize = [cropped size];
        NSLog(@"Cropped image to size %f %f", resultSize.width, resultSize.height);
    }
    else if (result.size.height >= target_height) {
        // resized image has height greater than target height, crop evenly
        int ydiff = result.size.height - target_height;
        CGRect targetFrame = CGRectMake(0, ydiff/2, target_width, target_height);
        cropped = [result croppedImage:targetFrame];
        CGSize resultSize = [cropped size];
        NSLog(@"Cropped image to size %f %f", resultSize.width, resultSize.height);
    }
    else { // (result.size.height < target_height) {
        // if the picture is not tall enough (a wide image from library), crop from left and right evenly
        float xdiff = result.size.width - target_width;
        CGRect cropFrame = CGRectMake(xdiff/2, 0, target_width, target_height);
        cropped = [result2 croppedImage:cropFrame];
        CGSize resultSize = [cropped size];
        NSLog(@"Cropped image to size %f %f", resultSize.width, resultSize.height);
    }
    
    CGSize fullSize = CGSizeMake(320, 480);
    if (cropped)
        cropped = [cropped resizedImage:fullSize interpolationQuality:kCGInterpolationHigh];
    */
    StickerPanelViewController * controller = [[StickerPanelViewController alloc] init];
    [controller setDelegate:self];
    [controller setBaseImage:final];
    [controller setHighResScale:highResScale];
    [self presentModalViewController:controller animated:YES];
}

-(UIImage *)rotateImage:(UIImage *)image withCurrentOrientation:(int)orient
{
    int kMaxResolution = 320; // Or whatever
    
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    
    CGFloat scaleRatio = 1; //bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    switch(orient) {
            
        case 1: // up
            transform = CGAffineTransformIdentity;
            /*
             if ([self.captureManager getMirrored]) {
             transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
             transform = CGAffineTransformScale(transform, -1.0, 1.0);
             }*/
            break;
        case 2: // down
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            if ([self.captureManager getMirrored]) {
                //                transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
                //                transform = CGAffineTransformScale(transform, 1.0, -1.0);
            }
            break;
            
        case 3: // left
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            if (![self.captureManager getMirrored]) {
                transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            } else {
                transform = CGAffineTransformRotate(transform, M_PI / 2.0);
                transform = CGAffineTransformTranslate(transform, -imageSize.width, -imageSize.height);
            }
            break;
            
        case 4: // right
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            if (![self.captureManager getMirrored]) {
                transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            } else {
                transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
                transform = CGAffineTransformTranslate(transform, -imageSize.width, -imageSize.height);
            }
            break;
            
        default:
            //            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation: %d", orient];
            transform = CGAffineTransformIdentity;
            /*
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Camera Error!" message:[NSString stringWithFormat:@"Invalid orientation: %d", orient] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
             [alert show];
             */
            break;
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == 3 || orient == 4) {   // landscape
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        //        if (![captureManager getMirrored])
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;  
}  


#pragma mark StickerPanelDelegate
-(void)closeStixPanel {
    [self dismissModalViewControllerAnimated:YES];
}
@end
