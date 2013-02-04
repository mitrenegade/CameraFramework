//
//  StixView.h
//  Stixx
//
//  Created by Bobby Ren on 12/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

// specifies a UIImageView that is overlaid with multiple stix, which can be manipulated

#import <UIKit/UIKit.h>
#import "Tag.h"
#import "StixAnimation.h"
#import "AsyncImageView.h"

//#import "StixPanelView.h" // cannot use this because of circular headers

@class StixView;

@protocol StixViewDelegate 
// stixView changed
-(void)stixDidChange;

@optional
-(NSString*) getUsername;
-(NSString*) getUsernameOfApp;
-(void)didAttachStix:(int)index;
-(void)didPeelStix:(int)index;
-(void)peelAnimationDidCompleteForStix:(int)index;
-(void)didTouchInStixView:(StixView*)stixViewTouched;

// multiple stix
-(void)didSelectStixInMultiStixView;

@end

@interface StixView : UIView <UIGestureRecognizerDelegate, UIActionSheetDelegate>
{
    // stix to be manipulated: new stix or new aux stix
    NSString * selectStixStringID;
    bool isDragging;
    bool isPinching;
    bool isTap; // tap on stix
    bool isTouch; // touch on stixView
    float offset_x, offset_y;
    
    CGSize originalImageSize;

    // these refer to the current active stix
    //float stixScale;
    //float stixRotation;
    CGAffineTransform referenceTransform;

    bool interactionAllowed;
    float imageScale;
    
    bool isPeelable;
    
    NSMutableArray * auxStixViews;
    NSMutableArray * auxStixStringIDs;
    //NSMutableArray * auxScales; // needed for touch test
    NSMutableArray * auxPeelableByUser;
    
    NSString * stixPeelSelected;
    CGPoint stixPeelSelectedCenter;
    
    bool showTransformCanvas;
    UIView * transformCanvas;

    NSMutableSet *_activeRecognizers;
    
    NSString * tagUsername;

    // key: stixStringID
    // value: array of all auxStix views of this type in this StixView
    // if at any point we've satisfied all stixStringIDs, repopulate this view
    BOOL isStillPeeling;
    
    // multi stix mode
    BOOL bMultiStixMode;
    int multiStixCurrent;
    NSMutableArray * transformBoxes;
}

@property (nonatomic, strong) UIImageView * stix;
@property (nonatomic, strong) UIImage * image;
@property (nonatomic, assign) bool interactionAllowed;
//@property (nonatomic, assign) float stixScale;
//@property (nonatomic, assign) float stixRotation;
@property (nonatomic) NSMutableArray * auxStixViews;
@property (nonatomic) NSMutableArray * auxStixStringIDs;
@property (nonatomic, assign) bool isPeelable;
@property (nonatomic, weak) id delegate;
@property (nonatomic, assign) CGAffineTransform referenceTransform;
@property (nonatomic, copy) NSString * selectStixStringID;
@property (nonatomic) NSNumber * tagID;
@property (nonatomic, assign) int stixViewID;
@property (nonatomic, assign) BOOL bMultiStixMode;

-(void)initializeWithImage:(UIImage*)imageData;
-(void)initializeWithImage:(UIImage*)imageData andStixLayer:(UIImage*)stixLayer;
-(int)populateWithAuxStixFromTag:(Tag*)tag;
-(void)populateWithStixForManipulation:(NSString*)stixStringID withCount:(int)count atLocationX:(int)x andLocationY:(int)y /*andScale:(float)scale andRotation:(float)rotation*/;
-(void)updateStixForManipulation:(NSString*)stixStringID;
-(bool)isStixPeelable:(int)index;
-(bool)isForeground:(CGPoint)point inStix:(UIImageView*)selectedStix;
-(void)doPeelAnimationForStix;

-(int)findPeelableStixAtLocation:(CGPoint)location;
-(void)transformBoxShowAtFrame:(CGRect)frame;
-(void)transformBoxShowAtFrame:(CGRect)frame withTransform:(CGAffineTransform)t;
-(void)addPeelableAnimationToStix:(UIImageView*)canvas;

// multi stix views
-(void)multiStixSelectCurrent:(int)stixIndex;
-(int)multiStixInitializeWithTag:(Tag *)tag useStixLayer:(BOOL)useStixLayer;
-(void)multiStixAddStix:(NSString*)stixStringID atLocationX:(int)x andLocationY:(int)y;
-(int) multiStixDeleteCurrentStix;
-(void) multiStixClearAllStix;

-(UIImageView*)getStixWithStixStringID:(NSString*)stixStringID;

@end
