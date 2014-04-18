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
#define STIX_FILENAMES_HAIR @"hair_afro", @"hair_blondshort", @"hair_blondwithbangs", @"hair_brownbangs", @"hair_brownlong", @"hair_celebrityboy", @"hair_curlylongblond", @"hair_dreadlocks", @"hair_eurostyle", @"hair_platinumblond", @"hair_redshorthair", @"hair_shortblondcosplayhair", @"hair_shortblondguy", @"hair_shortblue", @"hair_spikyblondcosplay", @"hipster_fauxhawk_hairstyle", @"hipster_girls_hairstyle"
#define STIX_FILENAMES_STACHE @"stache_fumanchu",@"stache_handlebar",@"stache_horseshoe",@"stache_oldman",@"stache_pencil",@"stache_walrus",@"stache_wedge",@"stache_western",@"stache_bushy", @"stache_rich", @"beard_scruffy", @"hipster_ironic_mustache"
#define STIX_FILENAMES_GLASSES @"eyes_crossed", @"eyes_puppy", @"glasses_3d_glasses", @"glasses_aviatorglasses", @"glasses_catglasses", @"hipster_chunkyframe_glasses", @"hipster_oversized_glasses", @"hipster_pinkshutter_glasses", @"glasses_01", @"glasses_02", @"glasses_03", @"glasses_04"
#define STIX_FILENAMES_MYSTERY  @"hat_browncap", @"hat_brownstripedcap", @"hat_fedora", @"hat_tophat", @"hipster_bluewovencap", @"hipster_truckerhat", @"hipster_tweed_fedora", @"nerdytie", @"furryears", @"kiss", @"mouth_buckteeth", @"mouth_toothy", @"mouth_toothy2", @"mouth_vampirefangs", @"fail", @"ftw", @"lol", @"yolo", @"omg", @"hearts1", @"heartsplenty", @"pink_splash", @"green_splash", @"blue_splash", @"musicnote", @"redfireball", @"blueflower", @"flowerpower", @"starexplode", @"swirlyribbons", @"yellowflowers", @"abstractbubbles", @"bunchofstars"

enum eStickerCollections {
    STICKER_COLLECTION_HAIR = 0,
    STICKER_COLLECTION_GLASSES,
    STICKER_COLLECTION_STACHE,
    STICKER_COLLECTION_MYSTERY,
    STICKER_COLLECTION_MAX
    };

@protocol StickerPanelDelegate <NSObject>

-(void)closeStixPanel;

@end

//typedef void (^userSelectionCallback)(NSString *);

@interface StickerPanelViewController : UIViewController <UIScrollViewDelegate, UIGestureRecognizerDelegate, StixViewDelegate, FBHelperDelegate, ShareViewDelegate, UIActionSheetDelegate, EmailLoginDelegate>
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
}
@property (nonatomic, weak) IBOutlet UIView * panelView;
@property (nonatomic, weak) IBOutlet UIScrollView * scrollView;
@property (nonatomic, weak) IBOutlet UIImageView * collectionName;

@property (nonatomic, weak) IBOutlet UIView * moreView;
//@property (nonatomic, weak) IBOutlet UIButton * buttonAddMore;
@property (nonatomic, weak) IBOutlet UIButton * buttonSave;

@property (nonatomic, weak) IBOutlet UIButton * buttonHair;
@property (nonatomic, weak) IBOutlet UIButton * buttonGlasses;
@property (nonatomic, weak) IBOutlet UIButton * buttonStache;
@property (nonatomic, weak) IBOutlet UIButton * buttonMystery;

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
