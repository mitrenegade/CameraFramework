//
//  StickerPanelViewController.h
//  Camera Framework App
//
//  Created by Bobby Ren on 1/27/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StixView.h"

#define STIX_PER_ROW 4
#define STIX_SIZE 70
#define SCROLL_OFFSET_OFF 550
#define SCROLL_OFFSET_ON 0
#define STIX_FILENAMES @"stache_fumanchu",@"stache_handlebar",@"stache_horseshoe",@"stache_oldman",@"stache_pencil",@"stache_walrus",@"stache_wedge",@"stache_western",@"stache_bushy", @"stache_rich", @"beard_scruffy", @"eyes_crossed", @"eyes_puppy", @"glasses_3d_glasses", @"glasses_aviatorglasses", @"hat_fedora", @"hat_tophat"
#define STIX_DESCRIPTIONS @"Fumanchu Mustache",@"Handlebar Mustache",@"Horseshoe Mustache",@"Old Man Mustache",@"Pencil Mustache",@"Walrus Mustache",@"Wedge Mustache",@"Western Mustache",@"Bushy Mushtache", @"Rich Mustache", @"Scruffy Beard", @"Crossed Eyes", @"Puppy Eyes", @"3D Glasses", @"Aviator Glasses", @"Fedora", @"Top Hat"

@protocol StickerPanelDelegate <NSObject>

-(void)closeStixPanel;

@end

@interface StickerPanelViewController : UIViewController <UIScrollViewDelegate, UIGestureRecognizerDelegate, StixViewDelegate>
{
    BOOL didInitializeImage; // because image is initialized on viewDidAppear
    BOOL didBurnImage; // whether image/stix was burned and uploaded to parse
}
@property (nonatomic, weak) IBOutlet UIView * panelView;
@property (nonatomic, weak) IBOutlet UIScrollView * scrollView;

@property (nonatomic, weak) IBOutlet UIView * moreView;
@property (nonatomic, weak) IBOutlet UIButton * buttonAddMore;
@property (nonatomic, weak) IBOutlet UIButton * buttonSave;

@property (nonatomic, strong) NSMutableArray * allStickerViews;
@property (nonatomic, weak) id delegate;

@property (nonatomic, strong) UIImage * baseImage;
@property (nonatomic, strong) UIImage * burnedImage;
@property (nonatomic, assign) float highResScale; // scale of actual image to editor frame
@property (nonatomic, strong) IBOutlet StixView * stixView;

-(void)initWithImage:(UIImage*)newImage;
-(IBAction)didClickAddMore:(id)sender;
-(IBAction)didClickSave:(id)sender;
//-(IBAction)didClickCancel:(id)sender;
-(IBAction)didClickClosePanel:(id)sender;
@end
