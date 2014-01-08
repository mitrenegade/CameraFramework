//
//  StickerPanelViewController.h
//  Camera Framework App
//
//  Created by Bobby Ren on 1/27/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StixView.h"
#import "MBProgressHUD.h"
#import "FBHelper.h"
#import "ShareViewController.h"
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>
#import "EmailLoginViewController.h"
#import "ParseTag.h"

#define STIX_PER_ROW 3
#define STIX_SIZE 90
#define SCROLL_OFFSET_OFF 650
#define SCROLL_OFFSET_ON 0
#define STIX_FILENAMES_CUTE @"1-babypenguin", @"2-giraffe", @"3-hippo", @"4-littlebear", @"5-panda2", @"6-panda3", @"7-bluepenguin", @"8-cherryblossomrabbits", @"9-babychick2", @"10-ladybug", @"11-mole", @"12-realteddybear", @"13-teddy", @"14-pawprint", @"15-pinkballoon", @"16-purplebutterfly", @"17-rainbow", @"18-bubble"
#define STIX_FILENAMES_HEART @"1-hearts1", @"2-heartsplenty", @"3-120_heart", @"4-red_glowing_heart", @"5-bemine", @"6-kiss", @"7-blueflower", @"8-flowerpower", @"9-redrose", @"10-tulip", @"11-yellowflowers", @"12-bunchofstars", @"13-pinkstar", @"14-starexplode", @"15-swirlyribbons", @"16-pinkflower"

enum eStickerCollections {
    STICKER_COLLECTION_HEART = 0,
    STICKER_COLLECTION_CUTE,
    STICKER_COLLECTION_MAX
    };

@protocol StickerPanelDelegate <NSObject>

-(void)closeStixPanel;

@end

//typedef void (^userSelectionCallback)(NSString *);

@interface StickerPanelViewController : UIViewController <UIScrollViewDelegate, UIGestureRecognizerDelegate, StixViewDelegate, FBHelperDelegate, ShareViewDelegate, UIActionSheetDelegate, EmailLoginDelegate, UITextViewDelegate>
{
    BOOL didInitializeImage; // because image is initialized on viewDidAppear
    BOOL didBurnImage; // whether image/stix was burned and uploaded to parse
    
    // for asynchronous uploading and user selection
    //userSelectionCallback facebookShareCallback;
    //userSelectionCallback twitterShareCallback;
    SEL facebookShareCallback;
    SEL twitterShareCallback;
    
    int stickerCollection;
    
    BOOL alreadySharedToFacebook;
    BOOL alreadySharedToTwitter;
    BOOL alreadySharedToInstagram;
    
    BOOL isDisplayingMysteryMessage;
    
    ACAccount * twitterAccount;

    ParseTag *currentParseTag;
    NSString *details;
    float textPosition;
    BOOL draggingTextBox;
    float textBoxDragOffset;
}
@property (nonatomic, weak) IBOutlet UIView * panelView;
@property (nonatomic, weak) IBOutlet UIScrollView * scrollView;
@property (nonatomic, weak) IBOutlet UIImageView * collectionName;
@property (weak, nonatomic) IBOutlet UILabel *labelRibbon;
@property (weak, nonatomic) IBOutlet UITextView *textViewComments;

@property (nonatomic, weak) IBOutlet UIView * moreView;
//@property (nonatomic, weak) IBOutlet UIButton * buttonAddMore;
@property (nonatomic, weak) IBOutlet UIButton * buttonSave;

@property (nonatomic, weak) IBOutlet UIButton * buttonCute;
@property (nonatomic, weak) IBOutlet UIButton * buttonHeart;
@property (nonatomic, weak) IBOutlet UIButton * buttonText;

@property (nonatomic, strong) NSMutableArray * allStickerViews;
@property (nonatomic, weak) id delegate;

@property (nonatomic, strong) UIImage * baseImage;
@property (nonatomic, strong) UIImage * burnedImage;
@property (nonatomic, assign) float highResScale; // scale of actual image to editor frame
@property (nonatomic, strong) IBOutlet StixView * stixView;
@property (nonatomic, strong) MBProgressHUD * progress;
@property (nonatomic, weak) IBOutlet UIImageView * instructionsView;

@property (nonatomic, strong) NSString * parseObjectID;
@property (nonatomic, strong) ShareViewController * shareViewController;

@property (nonatomic, strong) NSMutableArray * accountsArray;

-(void)initWithImage:(UIImage*)newImage;
-(IBAction)didClickAddMore:(id)sender;
-(IBAction)didClickSave:(id)sender;
-(IBAction)didClickClosePanel:(id)sender;
-(IBAction)didClickCancel:(id)sender;
-(IBAction)didClickDelete:(id)sender;
@end
