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

@implementation StickerPanelViewController

@synthesize scrollView;
@synthesize  allStickerViews;
@synthesize delegate;
@synthesize stixView;
@synthesize baseImage;
@synthesize burnedImage;
@synthesize highResScale;

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
}

-(void)reloadAllStickers {
    NSArray * stickerFilenames = @[STIX_FILENAMES];
    
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
        CGPoint stixCenter = CGPointMake(stixWidth*col + stixWidth / 2, stixHeight*row + stixHeight/2);
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
    [self.scrollView setContentSize:CGSizeMake(STIX_PER_ROW * stixWidth, (maxRows+1) * stixHeight)];
    NSLog(@"ScrollView frame %f %f %f %f contentSize: %f %f", scrollView.frame.origin.x, scrollView.frame.origin.y, scrollView.frame.size.width, scrollView.frame.size.height, scrollView.contentSize.width, scrollView.contentSize.height);
}

-(void)togglePanel:(BOOL)visible {
    if (visible) {
        CGRect frame = self.view.frame;
        frame.origin.y += SCROLL_OFFSET_ON;
        [self.panelView setFrame:frame];
        [self.moreView setHidden:YES];
    }
    else {
        CGRect frame = self.view.frame;
        frame.origin.y += SCROLL_OFFSET_OFF;
        [self.panelView setFrame:frame];
        [self.moreView setHidden:NO];
    }
}

-(IBAction)didClickAddMore:(id)sender {
    [self togglePanel:YES];
}

-(IBAction)didClickClosePanel:(id)sender {
    [self togglePanel:NO];
}

#pragma mark tapGestureRecognizer

-(void)tapGestureHandler:(UITapGestureRecognizer*) sender {
    NSArray * stickerDescriptions = @[STIX_DESCRIPTIONS];
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        // so tap is not continuously sent
        
        //NSLog(@"Double tap recognized!");
        CGPoint location = [sender locationInView:self.scrollView];
        for (UIImageView * stickerView in self.allStickerViews) {
            CGRect stickerFrame = [stickerView frame];
            if (CGRectContainsPoint(stickerFrame, location)) {
                int tag = stickerView.tag;
                NSString * stickerType = @[STIX_FILENAMES][tag];
                NSLog(@"Tapped sticker type: %@ index %d description %@", stickerType, tag, stickerDescriptions[tag]);
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
#if 0
        UIImage * stixLayer = [tag tagToUIImageUsingBase:NO retainStixLayer:YES useHighRes:YES];
        self.burnedImage = [self burnInImage:stixLayer];
        [self didClickSaveWithResult:self.burnedImage];
#else
        UIImage * stixLayer = [tag tagToUIImageUsingBase:NO retainStixLayer:YES useHighRes:YES];
        self.burnedImage = [tag tagToUIImageUsingBase:YES retainStixLayer:YES useHighRes:YES];
        [self didClickSaveWithResult:self.burnedImage];
#endif
        ParseTag * parseTag = [[ParseTag alloc] init];
        [parseTag setImage:stixView.image];
        [parseTag setStixLayer:stixLayer];
        [parseTag uploadWithBlock:^(NSString *newObjectID, BOOL didUploadImage) {
            if (didUploadImage) {
                NSLog(@"Uploaded new picture object to Parse with new objectID: %@...still uploading images to AWS in background", newObjectID);
            }
            else
                NSLog(@"Could not upload image to AWS! Parse objectID %@", newObjectID);
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
    
    [UIActionSheet actionSheetWithTitle:nil message:nil buttons:[NSArray arrayWithObjects:@"Save to Album", @"Facebook", @"Twitter", @"Instagram", nil] showInView:self.view onDismiss:^(int buttonIndex) {
        if (buttonIndex == 0) {
            // save to album
            [self saveToAlbum:result];
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"Sharing coming soon!" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            [self.moreView setHidden:NO];
        }
    } onCancel:^{
        [delegate closeStixPanel];
    }];
}

-(void)saveToAlbum:(UIImage*)image {
    NSString * title = @"Save to album";
    [[ALAssetsLibrary sharedALAssetsLibrary] saveImage:image toAlbum:@"Stix Album" withCompletionBlock:^(NSError *error) {
        if (error!=nil) {
            NSString * message = @"Image could not be saved!";
            [UIAlertView alertViewWithTitle:title message:message cancelButtonTitle:@"OK" otherButtonTitles:nil onDismiss:^(int buttonIndex) {
            } onCancel:^{
                [self didClickSaveWithResult:image];
            }];
        }
        else {
            NSString * message = @"Image saved to your album";
            [UIAlertView alertViewWithTitle:title message:message cancelButtonTitle:@"OK" otherButtonTitles:nil onDismiss:^(int buttonIndex) {
            } onCancel:^{
                [delegate closeStixPanel];
            }];
        }
    }];
}

@end

