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
#import <QuartzCore/QuartzCore.h>
#import "StoreKitHelper.h"
#import "Appirater.h"

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
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    int ct = [defaults integerForKey:@"mysteryPackCount"];
    if (ct >= MYSTERY_PACK_UNLOCK_COUNT) {
        // no mystery pack
    }

    BOOL firstTimeInstructionsClosed = [defaults boolForKey:@"firstTimeInstructions2"];
    if (firstTimeInstructionsClosed)
        [self.instructionsView setHidden:YES];;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishInstagramAuth) name:kInstagramAuthSuccessNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unlockMysteryPack) name:kDidUnlockMysteryPackNotification object:nil];
    
    UISwipeGestureRecognizer * swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeDown:)];
    [swipeGesture setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.panelView addGestureRecognizer:swipeGesture];

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    [panGesture setDelegate:self]; // enables shouldReceiveGesture
    [self.view addGestureRecognizer:panGesture];

    [self.textViewComments setHidden:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    textPosition = self.textViewComments.frame.origin.y;

    // add stixview
    if (didInitializeImage)
        return;

    didInitializeImage = YES;
    [self.stixView initializeWithImage:self.baseImage];
    NSLog(@"StixView frame: %f %f", stixView.frame.size.width, stixView.frame.size.height);
    NSLog(@"BaseImage size: %f %f", self.baseImage.size.width, self.baseImage.size.height);

    if ([self.textViewComments.text length] == 0)
        [self.textViewComments setHidden:YES];
    else
        [self.textViewComments setHidden:NO];
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
    if (stickerCollection == STICKER_COLLECTION_HEART) {
        stickerFilenames = @[STIX_FILENAMES_HEART];
        [collectionName setImage:[UIImage imageNamed:@"ribbon_red"]];
        [self.labelRibbon setText:@"Hearts"];
    }
    else if (stickerCollection == STICKER_COLLECTION_CUTE) {
        stickerFilenames = @[STIX_FILENAMES_CUTE];
        [collectionName setImage:[UIImage imageNamed:@"ribbon_blue"]];
        [self.labelRibbon setText:@"Cute"];
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
    if (button == self.buttonCute) {
        stickerCollection = STICKER_COLLECTION_HEART;
        [self togglePanel:YES];
#if !TESTING
        [Flurry logEvent:@"OPEN STICKER PANEL" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"Hair", @"CollectionName", nil]];
#endif
    }
    else if (button == self.buttonHeart) {
        stickerCollection = STICKER_COLLECTION_CUTE;
        [self togglePanel:YES];
#if !TESTING
        [Flurry logEvent:@"OPEN STICKER PANEL" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"Glasses", @"CollectionName", nil]];
#endif
    }
    else if (button == self.buttonText) {
#if !TESTING
        [Flurry logEvent:@"OPEN STICKER PANEL" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"Stache", @"CollectionName", nil]];
#endif

        [self.textViewComments setHidden:NO];
        [self.textViewComments becomeFirstResponder];
    }
}

-(IBAction)didClickClosePanel:(id)sender {
    // closes panel that displays sticker selection
    [self togglePanel:NO];
}

-(IBAction)didClickCancel:(id)sender {
    // cancels current photo/editing process
    [delegate closeStixPanel];
}

#pragma mark PanGestureRecognizer
-(void)handleGesture:(UIGestureRecognizer *)sender {
    UIGestureRecognizer *gesture = (UIGestureRecognizer *)sender;
    if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
        CGPoint point = [gesture locationInView:self.view];
        if (gesture.state == UIGestureRecognizerStateBegan) {
            if (CGRectContainsPoint(self.textViewComments.frame, point)) {
                draggingTextBox = YES;
                textBoxDragOffset = self.textViewComments.frame.origin.y - point.y;
            }
        }
        else if (gesture.state == UIGestureRecognizerStateChanged) {
            if (draggingTextBox) {
                if (point.y > self.view.frame.size.height - 60)
                    return;
                textPosition = point.y + textBoxDragOffset;
                CGRect frame = self.textViewComments.frame;
                frame.origin.y = textPosition;
                self.textViewComments.frame = frame;
            }
        }
        else if (gesture.state == UIGestureRecognizerStateEnded)
            draggingTextBox = NO;
    }
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        if ([self.textViewComments isHidden])
            return NO;
        if (CGRectContainsPoint(self.textViewComments.frame, [touch locationInView:self.view]) == NO)
            return NO;
    }
    return YES;
}

#pragma mark tapGestureRecognizer
-(void)tapGestureHandler:(UITapGestureRecognizer*) sender {
//    NSArray * stickerDescriptions = @[STIX_DESCRIPTIONS];
    NSArray * stickerFilenames;
    if (stickerCollection == STICKER_COLLECTION_HEART)
        stickerFilenames = @[STIX_FILENAMES_HEART];
    else if (stickerCollection == STICKER_COLLECTION_CUTE)
        stickerFilenames = @[STIX_FILENAMES_CUTE];

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

-(IBAction)didClickShare:(id)sender {
    [self save:0];
}
-(IBAction)didClickSend:(id)sender {
    [self save:1];
}

-(void)save:(int)sendOrShare{
    // 0 = share, 1 = send
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

        // HACK: complicated way to burn in other layers
        float scale = stixLayer.size.width / 320;
        CGRect frameLabel = self.textViewComments.frame;
        CGPoint center = self.textViewComments.center;
        center.x *= scale;
        center.y *= scale;
        UILabel *label = [[UILabel alloc] initWithFrame:frameLabel];
        label.backgroundColor = [UIColor blackColor];
        label.alpha = .6;
        label.textColor = [UIColor whiteColor];
        label.font = self.textViewComments.font;
        label.text = self.textViewComments.text;
        label.textAlignment = NSTextAlignmentCenter;
        label.transform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale);
        label.center = center;

        UIView *parent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, stixLayer.size.width, stixLayer.size.height)];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:stixLayer];
        [parent addSubview:imageView];
        [parent addSubview:label];
        UIGraphicsBeginImageContext(parent.frame.size);
        [parent.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        stixLayer = newImage;

        parent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, stixLayer.size.width, stixLayer.size.height)];
        imageView = [[UIImageView alloc] initWithImage:self.burnedImage];
        [parent addSubview:imageView];
        [parent addSubview:label];
        UIGraphicsBeginImageContext(parent.frame.size);
        [parent.layer renderInContext:UIGraphicsGetCurrentContext()];
        newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.burnedImage = newImage;

        [self didClickSaveWithResult:newImage sendOrShare:sendOrShare];

        ParseTag * parseTag = [[ParseTag alloc] init];
        currentParseTag = parseTag;
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
        [self didClickSaveWithResult:self.burnedImage sendOrShare:sendOrShare];
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

-(void)didClickSaveWithResult:(UIImage*)result sendOrShare:(int)sendOrShare {
    // 0 = share, 1 = send

    [self togglePanel:NO];
    [self.moreView setHidden:YES];
    
#if 0
    /*
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
     */
#elif 0
    /*
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
     */
#else
    // use activity sheet
    /*
     Activity types:
     NSString *const UIActivityTypePostToFacebook;
     NSString *const UIActivityTypePostToTwitter;
     NSString *const UIActivityTypePostToWeibo;
     NSString *const UIActivityTypeMessage;
     NSString *const UIActivityTypeMail;
     NSString *const UIActivityTypePrint;
     NSString *const UIActivityTypeCopyToPasteboard;
     NSString *const UIActivityTypeAssignToContact;
     NSString *const UIActivityTypeSaveToCameraRoll;
     NSString *const UIActivityTypeAddToReadingList;
     NSString *const UIActivityTypePostToFlickr;
     NSString *const UIActivityTypePostToVimeo;
     NSString *const UIActivityTypePostToTencentWeibo;
     NSString *const UIActivityTypeAirDrop;
     */

    if (sendOrShare == ACTION_SHARE) {
        NSString *textToShare = @"@heartfx";
        UIImage *imageToShare = result;
        NSArray *itemsToShare = @[textToShare, imageToShare];
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
        activityVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList, UIActivityTypeMessage, UIActivityTypeMail, UIActivityTypeAirDrop]; //or whichever you don't need
        [self presentViewController:activityVC animated:YES completion:nil];
    }
    else if (sendOrShare == ACTION_SEND) {
        resultToSend = result;
        if (![StoreKitHelper hasPostage] && ![StoreKitHelper hasLicense]) {
            [self promptForPurchase];
        }
        else {
            [self doActionSend];
        }
    }
#endif
}

-(void)doActionSend {
    UIImage *imageToShare = resultToSend;
    NSArray *itemsToShare = @[imageToShare];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypePostToFacebook, UIActivityTypePostToTwitter, UIActivityTypePostToWeibo, UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList, UIActivityTypeCopyToPasteboard, UIActivityTypeSaveToCameraRoll, UIActivityTypePostToFlickr, UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo]; //or whichever you don't need
    activityVC.completionHandler = ^(NSString *activityType, BOOL completed) {
        if ([StoreKitHelper hasLicense]) {
            NSLog(@"YAY");
            if (!completed) {
                [UIAlertView alertViewWithTitle:@"Send cancelled" message:@"You have the forever stamp. Click Send to send more valentines."];
            }
            else {
                [UIAlertView alertViewWithTitle:@"You sent a valentine." message:@"You have the forever stamp. Click Send to send more valentines."];
                [Appirater userDidSignificantEvent:YES];
            }
        }
        else if ([StoreKitHelper hasPostage]) {
            if (!completed) {
                int postageLeft = [StoreKitHelper postageCount];
                [UIAlertView alertViewWithTitle:@"Send cancelled" message:[NSString stringWithFormat:@"You still have %d postage stamps left", postageLeft]];
            }
            else {
                int postageLeft = [StoreKitHelper deductPostage];
                NSString *message = [NSString stringWithFormat:@"You still have %d postage stamps left", postageLeft];
                if (postageLeft == 0)
                    message = @"You have no more postage left.";
                [UIAlertView alertViewWithTitle:@"Thanks for sending!" message:message];

                [Appirater userDidSignificantEvent:YES];
            }
        }
    };
    [self presentViewController:activityVC animated:YES completion:nil];
}

-(void)promptForPurchase {
    [UIAlertView alertViewWithTitle:@"Purchase postage." message:@"Buy a stamp to send a valentine by email or text?" cancelButtonTitle:@"No thanks" otherButtonTitles:@[@"Send one email or text for $.99", @"Send unlimited valentines for $1.99"] onDismiss:^(int buttonIndex) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:StoreKitHelperProductFailedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFailPurchase:) name:StoreKitHelperProductFailedNotification object:nil];

        if (buttonIndex == 0) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:StoreKitHelperProductPurchasedNotification object:[StoreKitHelper postage].productIdentifier];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPurchase:) name:StoreKitHelperProductPurchasedNotification object:[StoreKitHelper postage].productIdentifier];

            // one purchase of postage
            [[StoreKitHelper sharedInstance] buyProduct:[StoreKitHelper postage]];
        }
        else if (buttonIndex == 1) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:StoreKitHelperProductPurchasedNotification object:[StoreKitHelper license].productIdentifier];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPurchase:) name:StoreKitHelperProductPurchasedNotification object:[StoreKitHelper license].productIdentifier];

            // one license
            [[StoreKitHelper sharedInstance] buyProduct:[StoreKitHelper license]];
        }
    } onCancel:nil];
}

-(void)didPurchase:(NSNotification *)notification {
    NSString * productIdentifier = notification.object;
    NSLog(@"Purchased: %@ license count: %d postage cont %d", productIdentifier, [StoreKitHelper hasLicense], [StoreKitHelper postageCount]);

    [self doActionSend];
}

-(void)didFailPurchase:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSLog(@"Failed purchase: %@", userInfo[@"error"]);
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
    PFFile *image = currentParseTag.pfObject[@"image"];
    PFFile *thumb = currentParseTag.pfObject[@"thumbnail"];
    NSString * imageLink = [image url];
    NSString * thumbLink = [thumb url];
    NSString * storeLink = @"http://bit.ly/ZIGKqr";
    NSMutableDictionary * params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                    imageLink, @"link",
                                    thumbLink, @"picture",
                                    @"My Heart FX Pic", @"name",
                                    @"Love and Peace #heartfx", @"caption",
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
    UIView *blankView = [[UIView alloc] initWithFrame:CGRectZero];
    self.progress.customView = blankView;
    self.progress.mode = MBProgressHUDModeCustomView;
    self.progress.animationType = MBProgressHUDAnimationZoom;
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
                            if (!self.burnedImage) {
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
                    UIView *blankView = [[UIView alloc] initWithFrame:CGRectZero];
                    self.progress.customView = blankView;
                    self.progress.mode = MBProgressHUDModeCustomView;
                    [self.progress setLabelText:@"Could not access Twitter!"];
                    [self.progress hide:YES afterDelay:1.5];
                }
            }];
        }
        else {
            UIView *blankView = [[UIView alloc] initWithFrame:CGRectZero];
            self.progress.customView = blankView;
            self.progress.mode = MBProgressHUDModeCustomView;
            self.progress.labelText = @"Could not access Twitter";
            [self.progress setDetailsLabelText:@"Please download the Twitter app or register your account in the iPhone Settings"];
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
    PFFile *imageFile = currentParseTag.pfObject[@"image"];
    [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            UIImage *img = [UIImage imageWithData:data];
            // image can now be set on a UIImageView
            [self iosSendTweetWithImage:twitterAccount image:img];
        }
    }];
}

-(void)iosSendTweetWithImage:(ACAccount *)twitterAccount image:(UIImage *)image {
    NSString *shareMessage = @"This is my favorite selfie! #heartfx"; // limited to 140
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com"
                  @"/1.1/statuses/update_with_media.json"];
    NSDictionary *params = @{@"status" : shareMessage};
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodPOST
                                                      URL:url
                                               parameters:params];
    NSData *imageData = UIImageJPEGRepresentation(image, 1.f);
    [request addMultipartData:imageData
                     withName:@"media[]"
                         type:@"image/jpeg"
                     filename:@"image.jpg"];
    [request setAccount:twitterAccount];
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(iosReceivedReplyWithResponse:error:) withObject:urlResponse withObject:error ];

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
        [MGInstagram postImage:self.burnedImage withCaption:@"#heartfx" inView:self.view];
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

#pragma mark TextViewDelegate
-(void)textViewDidEndEditing:(UITextView *)textView {
    if (textView.text.length == 0)
        [self.textViewComments setHidden:YES];
    CGRect frame = self.textViewComments.frame;
    if (textPosition > self.view.frame.size.height - 60)
        textPosition = self.view.frame.size.height - 80 - self.textViewComments.frame.size.height;
    frame.origin.y = textPosition;
    [UIView animateWithDuration:.3 animations:^{
        self.textViewComments.frame = frame;
    }];
}

- (BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{

    if ([text isEqualToString:@"\n"]) {
        // Be sure to test for equality using the "isEqualToString" message
        [textView resignFirstResponder];

        // Return FALSE so that the final '\n' character doesn't get added
        return NO;
    }
    NSString *oldComments = details;
    details = [textView.text stringByReplacingCharactersInRange:range withString:text];
    if ([details length] > 65) {
        details = oldComments;
        textView.text = oldComments;
        return NO;
    }

    return YES;
}

#pragma mark Keyboard
#pragma mark scrollview and keyboard
- (void)keyboardWillShow:(NSNotification *)n
{
    NSDictionary * userInfo = [n userInfo];

    // get the sizshouldbegine of the keyboard
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    // resize the noteView
    CGRect viewFrame = self.view.frame;
    CGRect frame = self.textViewComments.frame;
    frame.origin.y = viewFrame.size.height - (keyboardSize.height) - self.textViewComments.frame.size.height;

    [UIView animateWithDuration:.3 animations:^{
        self.textViewComments.frame = frame;
    } completion:^(BOOL finished) {
    }];
}

@end

