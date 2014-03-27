//
//  StickerPanelViewController.m
//  Camera Framework App
//
//  Created by Bobby Ren on 1/27/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import "StickerPanelViewController.h"
#import "ParseTag.h"
#import "UIActionSheet+MKBlockAdditions.h"
#import "UIAlertView+MKBlockAdditions.h"
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "FBHelper.h"
#import "AppDelegate.h"
#import "MGInstagram.h"
#import "Flurry.h"
#import "Constants.h"
#import "ParseHelper.h"
#import "EmailLoginViewController.h"

@implementation StickerPanelViewController

@synthesize scrollView;
@synthesize allStickerViews;
@synthesize delegate;
@synthesize stixView;
@synthesize baseImage;
@synthesize burnedImage;
@synthesize highResScale;
@synthesize progress;
@synthesize parseObjectID;

@synthesize buttonGlasses, buttonHair, buttonMystery, buttonSave, buttonStache;
@synthesize moreView, panelView, collectionName;
@synthesize shareViewController;
@synthesize accountsArray;
@synthesize instructionsView;

static AppDelegate * appDelegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:@"StickerPanelSelectorViewController" bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.allStickerViews= [[NSMutableArray alloc] init];
    
    // add gesture recognizer
    UITapGestureRecognizer * myTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureHandler:)];
    [myTapRecognizer setNumberOfTapsRequired:1];
    [myTapRecognizer setNumberOfTouchesRequired:1];
    [myTapRecognizer setDelegate:self];
    [self.scrollView addGestureRecognizer:myTapRecognizer];

    //[self.scrollView setBackgroundColor:[UIColor redColor]];
    [self reloadAllStickers];
    
    BOOL visible = YES;
    [self togglePanel:visible];
    
    [self.stixView setDelegate:self];
    [self.stixView setBMultiStixMode:YES];
    
    [buttonMystery setEnabled:NO];
    [buttonMystery setAlpha:.8];
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    int ct = [defaults integerForKey:@"mysteryPackCount"];
    if (ct >= MYSTERY_PACK_UNLOCK_COUNT) {
        [buttonMystery setEnabled:YES];
        [buttonMystery setAlpha:1];
    }

    BOOL firstTimeInstructionsClosed = [defaults boolForKey:@"firstTimeInstructions2"];
    if (firstTimeInstructionsClosed)
        [self.instructionsView setHidden:YES];;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishInstagramAuth) name:kInstagramAuthSuccessNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unlockMysteryPack) name:kDidUnlockMysteryPackNotification object:nil];
    
    UISwipeGestureRecognizer * swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeDown:)];
    [swipeGesture setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.panelView addGestureRecognizer:swipeGesture];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // add stixview
    if (didInitializeImage)
        return;

    didInitializeImage = YES;
    [self.stixView initializeWithImage:self.baseImage];
    NSLog(@"StixView frame: %f %f", stixView.frame.size.width, stixView.frame.size.height);
    NSLog(@"BaseImage size: %f %f", self.baseImage.size.width, self.baseImage.size.height);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kInstagramAuthSuccessNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDidUnlockMysteryPackNotification object:nil];
}

-(void)dealloc {
    //keyboard notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kInstagramAuthSuccessNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDidUnlockMysteryPackNotification object:nil];
}

-(void)reloadAllStickers {
    for (UIImageView * stickerImage in self.allStickerViews) {
        [stickerImage removeFromSuperview];
    }
    [self.allStickerViews removeAllObjects];

    NSArray * stickerFilenames;
    if (stickerCollection == STICKER_COLLECTION_HAIR) {
        stickerFilenames = @[STIX_FILENAMES_HAIR];
        [collectionName setImage:[UIImage imageNamed:@"ribbon_hair"]];
    }
    else if (stickerCollection == STICKER_COLLECTION_GLASSES) {
        stickerFilenames = @[STIX_FILENAMES_GLASSES];
        [collectionName setImage:[UIImage imageNamed:@"ribbon_glasses"]];
    }
    else if (stickerCollection == STICKER_COLLECTION_STACHE) {
        stickerFilenames = @[STIX_FILENAMES_STACHE];
        [collectionName setImage:[UIImage imageNamed:@"ribbon_staches"]];
    }
    else if (stickerCollection == STICKER_COLLECTION_MYSTERY) {
        stickerFilenames = @[STIX_FILENAMES_MYSTERY];
        [collectionName setImage:[UIImage imageNamed:@"ribbon_bonus"]];
    }
    
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Stickers" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    
    int stixWidth = STIX_SIZE + 10;
    int stixHeight = STIX_SIZE + 20;
    
    int ct = 0;
    int maxRows = 0;
    for (NSString * filename in stickerFilenames) {
        /*
        NSString * imageName = [bundle pathForResource:filename ofType:@"png"];
        UIImage * img = [[UIImage alloc] initWithContentsOfFile:imageName];
        UIImageView * stickerImage = [[UIImageView alloc] initWithImage:img];
         */
        UIImageView * stickerImage = [self.stixView getStixWithStixStringID:filename];
        [stickerImage setTag:ct];
        
        CGRect frame = CGRectMake(0, 0, STIX_SIZE, STIX_SIZE);
        [stickerImage setFrame:frame];

        int row = ct / STIX_PER_ROW;
        int col = ct - row * STIX_PER_ROW;
        CGPoint stixCenter = CGPointMake(stixWidth*col + stixWidth / 2, stixHeight*row + stixHeight/2 + stixHeight);
        [stickerImage setCenter:stixCenter];
        [self.scrollView addSubview:stickerImage];
        [self.allStickerViews addObject:stickerImage];
        NSLog(@"row, col %d %d", row, col);
        if (row > maxRows) {
            maxRows = row;
            NSLog(@"Max rows: %d", maxRows);
        }
        
        //NSLog(@"Adding sticker %d to panel: %@ frame %f %f %f %f", ct, imageName, stickerImage.frame.origin.x, stickerImage.frame.origin.y, stickerImage.frame.size.width, stickerImage.frame.size.height);
        ct++;
    }
    [self.scrollView setContentSize:CGSizeMake(STIX_PER_ROW * stixWidth, (maxRows+2) * stixHeight)];
    NSLog(@"ScrollView frame %f %f %f %f contentSize: %f %f", scrollView.frame.origin.x, scrollView.frame.origin.y, scrollView.frame.size.width, scrollView.frame.size.height, scrollView.contentSize.width, scrollView.contentSize.height);
}

-(void)togglePanel:(BOOL)visible {
    if (visible) {
        CGRect frame = self.view.frame;
        frame.origin.y += SCROLL_OFFSET_ON;
        [self reloadAllStickers];
        [UIView animateWithDuration:.5 animations:^{
            [self.panelView setFrame:frame];
        } completion:^(BOOL finished) {
            [self.moreView setHidden:YES];
        }];
    }
    else {        
        CGRect frame = self.view.frame;
        frame.origin.y += SCROLL_OFFSET_OFF;
        [UIView animateWithDuration:.5 animations:^{
            [self.panelView setFrame:frame];
        } completion:^(BOOL finished) {
            [self.moreView setHidden:NO];
        }];
    }
}

-(void)didSwipeDown:(id)sender {
    [self togglePanel:NO];
}

-(IBAction)didClickAddMore:(id)sender {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"firstTimeInstructions2"];
    [self.instructionsView setHidden:YES];
    
    UIButton * button = (UIButton*)sender;
    if (button == buttonHair) {
        stickerCollection = STICKER_COLLECTION_HAIR;
#if !TESTING
        [Flurry logEvent:@"OPEN STICKER PANEL" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"Hair", @"CollectionName", nil]];
#endif
    }
    else if (button == buttonGlasses) {
        stickerCollection = STICKER_COLLECTION_GLASSES;
#if !TESTING
        [Flurry logEvent:@"OPEN STICKER PANEL" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"Glasses", @"CollectionName", nil]];
#endif
    }
    else if (button == buttonStache) {
        stickerCollection = STICKER_COLLECTION_STACHE;
#if !TESTING
        [Flurry logEvent:@"OPEN STICKER PANEL" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"Stache", @"CollectionName", nil]];
#endif
    }
    else if (button == buttonMystery) {
        stickerCollection = STICKER_COLLECTION_MYSTERY;
#if !TESTING
        [Flurry logEvent:@"OPEN STICKER PANEL" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"Mystery", @"CollectionName", nil]];
#endif
    }
    [self togglePanel:YES];
}

-(IBAction)didClickClosePanel:(id)sender {
    [self togglePanel:NO];
}

-(IBAction)didClickCancel:(id)sender {
    [delegate closeStixPanel];
}
#pragma mark tapGestureRecognizer

-(void)tapGestureHandler:(UITapGestureRecognizer*) sender {
//    NSArray * stickerDescriptions = @[STIX_DESCRIPTIONS];
    NSArray * stickerFilenames;
    if (stickerCollection == STICKER_COLLECTION_HAIR)
        stickerFilenames = @[STIX_FILENAMES_HAIR];
    else if (stickerCollection == STICKER_COLLECTION_GLASSES)
        stickerFilenames = @[STIX_FILENAMES_GLASSES];
    else if (stickerCollection == STICKER_COLLECTION_STACHE)
        stickerFilenames = @[STIX_FILENAMES_STACHE];
    else if (stickerCollection == STICKER_COLLECTION_MYSTERY)
        stickerFilenames = @[STIX_FILENAMES_MYSTERY];
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        // so tap is not continuously sent
        
        //NSLog(@"Double tap recognized!");
        CGPoint location = [sender locationInView:self.scrollView];
        for (UIImageView * stickerView in self.allStickerViews) {
            CGRect stickerFrame = [stickerView frame];
            if (CGRectContainsPoint(stickerFrame, location)) {
                int tag = stickerView.tag;
                NSString * stickerType = stickerFilenames[tag];
                //NSLog(@"Tapped sticker type: %@ index %d description %@", stickerType, tag, stickerDescriptions[tag]);
                [self didTapStickerOfType:stickerType];
            }
        }
    }
}

-(void)didTapStickerOfType:(NSString*)stickerType {
    NSLog(@"Tapped sticker %@!", stickerType);
    [self togglePanel:NO];

    CGPoint center = stixView.center;
    // location is in TagDescriptorController's view
    center.x -= stixView.frame.origin.x;
    center.y -= stixView.frame.origin.y;
    
    [self.stixView setInteractionAllowed:YES];
    [self.stixView multiStixAddStix:stickerType atLocationX:center.x andLocationY:center.y];
    
    didBurnImage = NO;
}

-(void)stixDidChange {
    didBurnImage = NO;
}

-(IBAction)didClickSave:(id)sender {
    NSMutableArray * auxStixViews = [stixView auxStixViews];
    int ct = [auxStixViews count];
#if !TESTING
    [Flurry logEvent:@"SAVE BUTTON PRESSED" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:ct], @"NumberOfStixAdded", nil]];
#endif
    // burn all stix into stixLayer image
    if (!didBurnImage) {
        //UIImage * stixLayer = [self stixLayerFromAuxStix:auxStixViews];
        //UIImage * result = [self burnInImage:stixLayer];
        Tag * tag = [[Tag alloc] init];
        UIImage * image = stixView.image;
        [tag addImage:stixView.image];
        [tag setHighResImage:stixView.image];
        [tag setHighResScale:self.highResScale];
        NSMutableArray * auxStixStrings = stixView.auxStixStringIDs;
        for (int i=0; i<[auxStixStrings count]; i++) {
            UIImageView * stix = [auxStixViews objectAtIndex:i];
            
            // we initially transform all imagery by a certain scale
            CGAffineTransform scaleTransform = CGAffineTransformFromString([stixView.auxStixScaleTransforms objectAtIndex:i]);
            CGAffineTransform finalTransform = CGAffineTransformConcat(scaleTransform, stix.transform);
            [tag addStix:[auxStixStrings objectAtIndex:i] withLocation:stix.center withTransform:finalTransform withPeelable:NO];
        }
        UIImage * stixLayer = [tag tagToUIImageUsingBase:NO retainStixLayer:YES useHighRes:YES];
        self.burnedImage = [tag tagToUIImageUsingBase:YES retainStixLayer:YES useHighRes:YES];
        [self didClickSaveWithResult:self.burnedImage];

        ParseTag * parseTag = [[ParseTag alloc] init];
        //[parseTag setImage:stixView.image];
        [parseTag setImage:self.burnedImage];
        [parseTag setStixLayer:stixLayer];
        CGSize thumbSize = CGSizeMake(96, 155);
        [parseTag setThumbnail:[self.burnedImage resizedImage:thumbSize interpolationQuality:kCGInterpolationHigh]];
        //[parseTag uploadWithBlock:^(NSString *newObjectID, BOOL didUploadImage) {
        [parseTag saveOrUpdateToParseWithCompletion:^(BOOL success) {
            if (success) {
                parseObjectID = parseTag.pfObject.objectId;
                if (facebookShareCallback) {
                    [self performSelector:facebookShareCallback];
                }
                if (twitterShareCallback) {
                    [self performSelector:twitterShareCallback];
                }
            }
            else
                NSLog(@"Could not upload image to AWS! Parse objectID %@", parseTag.pfObject.objectId);
        }];
        
        didBurnImage = YES;
    }
    else {
        [self didClickSaveWithResult:self.burnedImage];
    }
}

-(UIImage *)burnInImage:(UIImage*)stixLayer {
    // set size of canvas
    CGSize newSize = self.stixView.frame.size;
    CGSize highResSize = [self.stixView.image size];
    UIGraphicsBeginImageContext(newSize);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGRect fullFrame = CGRectMake(0, 0, newSize.width, newSize.height);
    [self.stixView.image drawInRect:fullFrame];
    CGContextSaveGState(currentContext);
    [stixLayer drawInRect:fullFrame];
    // Get an image from the context
    UIImage * result = UIGraphicsGetImageFromCurrentImageContext(); //[UIImage imageWithCGImage: CGBitmapContextCreateImage(currentContext)];
    UIGraphicsEndImageContext();
    return result;
}

-(UIImage *)stixLayerFromAuxStix:(NSMutableArray *) auxStixViews {
    // doesn't work like tag
    /*
    // set size of canvas
    CGSize newSize;
    newSize = self.stixView.frame.size;
    UIImage * result = nil;
    // add all stix that are currently in auxStix lists
    for (UIImageView * nextStix in auxStixViews) {
        // resize and rotate stix image source to correct auxTransform
        CGSize stixSize = nextStix.frame.size;
        UIGraphicsBeginImageContext(newSize);
        CGContextRef currentContext = UIGraphicsGetCurrentContext();
        
        if (result) {
            // add previous result
            CGRect fullFrame = CGRectMake(0, 0, newSize.width, newSize.height);
            [result drawInRect:fullFrame];
        }
        // save state
        CGContextSaveGState(currentContext);

        // center context around center of stix
        CGPoint location = nextStix.center;
        CGContextTranslateCTM(currentContext, location.x, location.y);
        
        // apply stix's transform about this anchor point
        CGContextConcatCTM(currentContext, nextStix.transform);
        
        // offset by portion of bounds left and above anchor point
        CGContextTranslateCTM(currentContext, -stixSize.width/2, -stixSize.height/2);
        
        // render
        [[nextStix layer] renderInContext:currentContext];
        
        // restore state
        CGContextRestoreGState(currentContext);
        
        // Get an image from the context
        result = UIGraphicsGetImageFromCurrentImageContext(); //[UIImage imageWithCGImage: CGBitmapContextCreateImage(currentContext)];
        UIGraphicsEndImageContext();
    }
    // save edited image to photo album
    return result;
     */
    return nil;
}

-(void)didClickSaveWithResult:(UIImage*)result {
    [self togglePanel:NO];
    [self.moreView setHidden:YES];
    
#if 0
    [UIActionSheet actionSheetWithTitle:nil message:nil buttons:[NSArray arrayWithObjects:@"Save to Album", @"Facebook", @"Twitter", @"Instagram", nil] showInView:self.view onDismiss:^(int buttonIndex) {
        
        if (buttonIndex == 0) {
            // save to album
            [self saveToAlbum:result];
            self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [self.progress setLabelText:@"Saving..."];
            
        }
        else if (buttonIndex == 1) {
            // facebook
            FBHelper * fbHelper = [[FBHelper alloc] init];
            fbHelper.delegate = self;
            [fbHelper openSession];
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"Sharing coming soon!" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            [self.moreView setHidden:NO];
        }
    } onCancel:^{
        [delegate closeStixPanel];
    }];
#else
    // save to album
    NSString * title = @"Save to album";
    self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.progress setLabelText:@"Saving..."];
    [[ALAssetsLibrary sharedALAssetsLibrary] saveImage:result toAlbum:@"Stix Album" withCompletionBlock:^(NSError *error) {
        [self.progress hide:YES];
        if (error!=nil) {
            NSString * message = @"Image could not be saved!";
            [UIAlertView alertViewWithTitle:title message:message cancelButtonTitle:@"Try again" otherButtonTitles:nil onDismiss:^(int buttonIndex) {
            } onCancel:^{
                [self didClickSaveWithResult:result];
            }];
        }
        else {
            NSString * message = @"Saved to album";
            [self.progress setLabelText:message];
            [self.stixView multiStixSelectCurrent:-1]; // remove transform box
            [self openShareView];
//            [self presentModalViewController:shareViewController animated:YES];
        }
    }];
#endif
}

-(IBAction)didClickDelete:(id)sender {
    NSLog(@"Did click delete stix");
    // delete currently selected stix
    int stixLeft = [stixView multiStixDeleteCurrentStix];
}

-(void)didClickFacebookShare {
    // facebook
    NSLog(@"Did click facebook share");
    if (alreadySharedToFacebook) {
        self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        progress.mode = MBProgressHUDModeText;
        [self.progress setLabelText:@"Already shared to Facebook!"];
        [self.progress hide:YES afterDelay:1.5];
        return;
    }
    self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.progress setLabelText:@"Uploading to Facebook..."];
    
#if !TESTING
    [Flurry logEvent:@"SHARE BUTTON PRESSED" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"Facebook", @"Channel", nil]];
#endif
    FBHelper * fbHelper = [[FBHelper alloc] init];
    fbHelper.delegate = self;
    [fbHelper openSession];
}

-(void)didOpenSession {
    NSLog(@"Did open session!");
    
    if (parseObjectID) {
        // object has been uploaded to parse thus an image ID has been generated
        //[self publishStory];
        // there's a facebook race condition where you have to request basic read permissions first, then request publish permissions.
        // if we don't delay, then the read permissions get requested first even though it is in the completion block. and nothing good happens.
        [self performSelector:@selector(prePublishStory) withObject:nil afterDelay:1.5];
    }
    else {
        // parse has not created the object ID, so just set a callback to come back
        facebookShareCallback = @selector(prePublishStory);
    }
}

-(void)prePublishStory {
    NSLog(@"Prepublish!");
    FBHelper * fbHelper = [[FBHelper alloc] init];
    fbHelper.delegate = self;
    [fbHelper requestPublish];
}

-(void)didGetPublishPermissions {
    NSLog(@"Publishing story");
    [self publishStory];
}

- (void)publishStory
{
    NSLog(@"Upload to facebook publishing story");
    NSString * imageLink = [NSString stringWithFormat:@"https://s3.amazonaws.com/%@/%@", IMAGE_URL_BUCKET, parseObjectID];
    NSString * thumbLink = [NSString stringWithFormat:@"https://s3.amazonaws.com/%@/%@", THUMBNAIL_IMAGE_URL_BUCKET, parseObjectID];
    NSString * storeLink = @"http://bit.ly/ZIGKqr";
    NSMutableDictionary * params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                    imageLink, @"link",
                                    thumbLink, @"picture",
                                    @"My pic from Face FX Cam", @"name",
                                    @"3 in 1 photobooth! #facefxcam", @"caption",
                                    //                                        @"Description", @"description",
                                    nil];
    [FBRequestConnection startWithGraphPath:@"me/feed" parameters:params HTTPMethod:@"POST"
                          completionHandler:^(FBRequestConnection *connection,
                                              id result,
                                              NSError *error) {
                              NSString *alertText;
                              if (error) {
                                  NSDictionary * userInfo = error.userInfo;
                                  NSDictionary * response = [userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"];
                                  NSDictionary * body = [response objectForKey:@"body"];
                                  NSNumber * code = [response objectForKey:@"code"];
                                  NSLog(@"Error code: %@", code);
                                  if ([code intValue] == 403) {
                                      NSLog(@"Need reauth!");
                                  }
                                  FBHelper * fbHelper = [[FBHelper alloc] init];
                                  fbHelper.delegate = self;
                                  [fbHelper openSession];
                              }
                              else {
                                  progress.mode = MBProgressHUDModeText;
                                  [self.progress setLabelText:@"Done!"];
                                  [self.progress hide:YES afterDelay:1.5];
                                  //[delegate performSelector:@selector(closeStixPanel) withObject:nil afterDelay:1.5];
                                  alreadySharedToFacebook = YES;
#if !TESTING
                                  [Flurry logEvent:@"SHARE COMPLETED" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"Facebook", @"Channel", nil]];
#endif
                                  [appDelegate incrementMysteryPackCount];
                              }
                          }];
}

-(void)didFailOpen {
    [self.progress hide:YES];
}

-(void)openShareView {
    if (!self.shareViewController) {
        self.shareViewController = [[ShareViewController alloc] init];
        self.shareViewController.delegate = self;
        [self.view addSubview:shareViewController.view];
        CGRect frame = shareViewController.view.frame;
        frame.origin.y = self.view.frame.size.height + 10;
        shareViewController.view.frame = frame; // start offscreen
    }
    CGRect frame = shareViewController.view.frame;
    frame.origin.y = self.view.frame.size.height - frame.size.height;
    [UIView animateWithDuration:.25 animations:^{
        self.shareViewController.view.frame = frame;
    }];
}

-(void)closeShareView {
    CGRect frame = shareViewController.view.frame;
    frame.origin.y = self.view.frame.size.height + 10;
    [UIView animateWithDuration:.25 animations:^{
        self.shareViewController.view.frame = frame;
    }completion:^(BOOL finished) {
//        [delegate closeStixPanel];
        [self.moreView setHidden:NO];
    }];
    
}

#pragma mark twitter

-(void)didClickTwitterShare {
    if (alreadySharedToTwitter) {
        self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        progress.mode = MBProgressHUDModeText;
        [self.progress setLabelText:@"Already shared to Twitter!"];
        [self.progress hide:YES afterDelay:1.5];
        return;
    }
    
#if !TESTING
    [Flurry logEvent:@"SHARE BUTTON PRESSED" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"Twitter", @"Channel", nil]];
#endif
    self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.progress setLabelText:@"Uploading to Twitter..."];
    
    // twitterAuth
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0){
        if ([TWTweetComposeViewController canSendTweet]){
            ACAccountStore *accountStore = [[ACAccountStore alloc] init];
            
            // Create an account type that ensures Twitter accounts are retrieved.
            ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
            
            // Request access from the user to use their Twitter accounts.
            [accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) {
                if(granted) {
                    // Get the list of Twitter accounts.
                    self.accountsArray = [NSMutableArray arrayWithArray: [accountStore accountsWithAccountType:accountType]];
                    // For the sake of brevity, we'll assume there is only one Twitter account present.
                    // You would ideally ask the user which account they want to tweet from, if there is more than one Twitter account present.
                    if ([accountsArray count] == 1) {
                        // Grab the initial Twitter account to tweet from.
                        twitterAccount = [accountsArray objectAtIndex:0];
                        NSError * twitError;
                        
                        // save twitter choice
                        NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
                        [userDefaults setObject:twitterAccount.identifier forKey:@"TwitterPreferredHandle"];
                        [userDefaults synchronize];
                        //twitterAccount.
                        // Create a request, which in this example, posts a tweet to the user's timeline.
                        // This example uses version 1 of the Twitter API.
                        // This may need to be changed to whichever version is currently appropriate.
                        [self iosSendTweet];
                    }
                    else if ([accountsArray count] > 1) {
                        NSError * twitError;
                        ACAccount * foundAccount = nil;
                        NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
                        BOOL found = NO;
                        if ([userDefaults objectForKey:@"TwitterPreferredHandle"] != nil) {
                            NSString * preferredAccount = [userDefaults objectForKey:@"TwitterPreferredHandle"];
                            for (ACAccount * ac in accountsArray) {
                                NSLog(@"Searching for preferred twitter handle %@: current %@", preferredAccount, ac.identifier);
                                if ([ac.identifier isEqualToString:preferredAccount]) {
                                    found = YES;
                                    foundAccount = ac;
                                    twitterAccount = foundAccount;
                                    break;
                                }
                            }
                        }
                        
                        if (!found) {
                            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Account", @"Change Profile Picture")                                                                                     delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:nil];
                            for (ACAccount *account in accountsArray) {
                                [actionSheet addButtonWithTitle:account.username];
                            }
                            actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
                            
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                [actionSheet showFromRect:self.view.frame inView:self.view animated:YES];
                            });
                            // show from our table view (pops up in the middle of the table)
                        }
                        else {
                            if (!parseObjectID) {
                                NSLog(@"No object id yet! set a callback!");
                                twitterShareCallback = @selector(iosSendTweet);
                            }
                            else {
                                [self iosSendTweet];
                            }
                        }
                    }
                }
                else {
                    progress.mode = MBProgressHUDModeText;
                    [self.progress setLabelText:@"Could not access Twitter accounts!"];
                    [self.progress hide:YES afterDelay:1.5];
                }
            }];
        }
        else {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't access Twitter" message:@"Please download the Twitter app or register your account in the iPhone Settings" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            progress.mode = MBProgressHUDModeText;
            [self.progress setLabelText:@"Please download the Twitter app or register your account in the iPhone Settings"];
            [self.progress hide:YES afterDelay:3];
#if !TESTING
            [Flurry logEvent:@"SHARE INCOMPLETE" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"Twitter", @"Channel", nil]];
#endif
        }
        
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSLog(@"No account selected");
        [self.progress setLabelText:@"Twitter share cancelled"];
        [self.progress hide:YES afterDelay:3];
    }
    else {
        twitterAccount = [accountsArray objectAtIndex:(buttonIndex - 1)];
        
        // save twitter choice
        NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:twitterAccount.identifier forKey:@"TwitterPreferredHandle"];
        [userDefaults synchronize];
        NSLog(@"Setting default twitter account to %@", twitterAccount.identifier);
        [self iosSendTweet];
    }
}

-(void)iosSendTweet {
    NSString * imageLink = [NSString stringWithFormat:@"https://s3.amazonaws.com/%@/%@", IMAGE_URL_BUCKET, parseObjectID];
    TWRequest *postRequest = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.json"] parameters:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"This is me after too many drinks %@ #facefxcam http://bit.ly/ZIGKqr", imageLink] forKey:@"status"] requestMethod:TWRequestMethodPOST];
    
    // Set the account used to post the tweet.
    [postRequest setAccount:twitterAccount];
    
    // Perform the request created above and create a handler block to handle the response.
    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSLog(@"Twitter sent!");
            progress.mode = MBProgressHUDModeText;
            [self.progress setLabelText:@"Done!"];
            [self.progress hide:YES afterDelay:1.5];
            //[delegate performSelector:@selector(closeStixPanel) withObject:nil afterDelay:1.5];
            alreadySharedToTwitter = YES;
            [appDelegate incrementMysteryPackCount];

#if !TESTING
            [Flurry logEvent:@"SHARE COMPLETED" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"Twitter", @"Channel", nil]];
#endif
        });
    }];
}

-(void)iosReceivedReplyWithResponse: (NSHTTPURLResponse*)response error: (NSError*) error {
    NSLog(@"Response: %@ error: %@", response, error);
}

#pragma mark instagram

-(void)didClickInstagramShare {
#if !TESTING
    [Flurry logEvent:@"SHARE BUTTON PRESSED" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"Instagram", @"Channel", nil]];
#endif
    [self didFinishInstagramAuth];
}

-(void)didFinishInstagramAuth {
    // do the post here
    if ([MGInstagram isAppInstalled] == NO) {
        self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        progress.mode = MBProgressHUDModeText;
        [self.progress setLabelText:@"Please download Instagram!"];
        [self.progress hide:YES afterDelay:1.5];

#if !TESTING
        [Flurry logEvent:@"SHARE INCOMPLETE" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"Instagram", @"Channel", nil]];
#endif
    }
    else {
        self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [self.progress setLabelText:@"Opening in Instagram..."];
        [self.progress hide:YES afterDelay:1.5];
        [MGInstagram postImage:self.burnedImage withCaption:@"#facefxcam 3 in 1 photobooth: http://bit.ly/ZIGKqr" inView:self.view];
#if !TESTING
        [Flurry logEvent:@"SHARE COMPLETED" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"Instagram", @"Channel", nil]];
#endif
        // for instagram, only give credit on the first time
        if (!alreadySharedToInstagram) {
            [appDelegate incrementMysteryPackCount];
            alreadySharedToInstagram = YES;
        }
    }
}

-(void)unlockMysteryPack {
    if (isDisplayingMysteryMessage)
        return;
    isDisplayingMysteryMessage = YES;
    
    [self.buttonMystery setEnabled:YES];
    [buttonMystery setAlpha:1];
    [[UIAlertView alertViewWithTitle:@"Mystery pack unlocked!" message:@"You have received a new sticker pack to play with!" cancelButtonTitle:@"Yay!" otherButtonTitles:nil onDismiss:^(int buttonIndex) {
        
    } onCancel:^{
        isDisplayingMysteryMessage = NO;
    }] show];

#if !TESTING
    [Flurry logEvent:@"MYSTERY PACK UNLOCKED"];
#endif
}

#pragma mark Contacts share
-(void)didClickContactsShare {
    if ([PFUser currentUser]) {
        NSLog(@"Logged in!");
    }
    else {
        EmailLoginViewController *loginController = [[EmailLoginViewController alloc] init];
        [loginController setDelegate:self];
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginController];
        [nav.navigationBar setTranslucent:NO];
        [nav.navigationBar setBackgroundColor:[UIColor redColor]];

        [self presentViewController:nav animated:YES completion:nil];
        loginController.navigationController.navigationBar.tintColor = [UIColor redColor];
    }
}

-(void)didLoginPFUser:(PFUser *)user withUserInfo:(UserInfo *)userInfo {
    NSLog(@"Logged in");
}
@end

