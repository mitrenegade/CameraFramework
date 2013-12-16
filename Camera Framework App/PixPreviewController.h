//
//  PixPreviewController.h
//  Stixx
//
//  Created by Bobby Ren on 6/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoadingAnimationView.h"
#import "Constants.h"
#import "StickerPanelViewController.h"

@protocol PixPreviewDelegate

-(void)didConfirmPix;
-(void)didCancelPix;

@end

@interface PixPreviewController : UIViewController <StickerPanelDelegate, UINavigationControllerDelegate>
{
    IBOutlet UIImageView * imageView;
	IBOutlet UIButton * buttonOK;
	IBOutlet UIButton * buttonCancel;
    LoadingAnimationView * activityIndicatorLarge;
}

@property (nonatomic) IBOutlet UIImageView * imageView;
@property (nonatomic) IBOutlet UIButton * buttonOK;
@property (nonatomic) IBOutlet UIButton * buttonCancel;
@property (nonatomic, weak) id delegate;
@property (nonatomic) LoadingAnimationView * activityIndicatorLarge;

-(IBAction)didClickOK:(id)sender;
-(IBAction)didClickBackButton:(id)sender;
-(void)initWithImage:(UIImage*)newImage;
-(void)startActivityIndicatorLarge;
-(void)stopActivityIndicatorLarge;
@end
