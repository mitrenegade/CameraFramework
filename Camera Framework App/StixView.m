//
//  StixView.m
//  Stixx
//
//  Created by Bobby Ren on 12/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StixView.h"
#import <QuartzCore/QuartzCore.h>
#define USE_STIXPANEL_VIEW 0

@implementation StixView

@synthesize stix;
@synthesize image;
@synthesize interactionAllowed;
//@synthesize stixScale;
//@synthesize stixRotation;
@synthesize auxStixViews, auxStixStringIDs;
@synthesize isPeelable;
@synthesize delegate;
@synthesize referenceTransform;
@synthesize selectStixStringID;
@synthesize tagID;
@synthesize stixViewID;
@synthesize bMultiStixMode;

static int currentStixViewID = 0;

-(UIImageView*)getStixWithStixStringID:(NSString*)stixStringID {
    // returns a half size image view
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Stickers" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    NSString *imageName = [bundle pathForResource:stixStringID ofType:@"png"];
    UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 120*.65, 120*.65)];
    UIImage *img = [[UIImage alloc] initWithContentsOfFile:imageName];
    imageView.image = img;
    CGRect frame = imageView.frame;
    frame.size.width = 120*.65;
    frame.size.height = 120*.65;
    [imageView setFrame:frame];
    return imageView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        interactionAllowed = YES;
        
        stixViewID = currentStixViewID++;
    }
    return self;
}

// populates with the image data for the pix
-(void)initializeWithImage:(UIImage *)imageData {
    [self initializeWithImage:imageData andStixLayer:nil];
}
-(void)initializeWithImage:(UIImage*)imageData andStixLayer:(UIImage*)stixLayer {
    if (auxStixViews == nil) {
        auxStixViews = [[NSMutableArray alloc] init];
        auxStixStringIDs = [[NSMutableArray alloc] init];
    }

    self.image = imageData;
    originalImageSize = [self.image size];
    CGRect frame = self.frame;
    frame.origin.x = 0;
    frame.origin.y = 0;
    UIImageView * imageView;
    if (stixLayer) {
        CGSize newSize = self.frame.size;
        UIGraphicsBeginImageContext(newSize);
        [self.image drawInRect:frame];
        [stixLayer drawInRect:frame];
        UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();	
        imageView = [[UIImageView alloc] initWithImage:result];
    }
    else {
        imageView = [[UIImageView alloc] initWithFrame:frame];
        [imageView setImage:self.image];
    }
    [self addSubview:imageView];
    _activeRecognizers = [[NSMutableSet alloc] init];
    isStillPeeling = NO;

    // add pinch and rotate gesture recognizer
    UIPinchGestureRecognizer * myPinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)]; //(pinchGestureHandler:)];
    [myPinchRecognizer setDelegate:self];
    
    UIRotationGestureRecognizer *myRotateRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)]; //(pinchRotateHandler:)];
    [myRotateRecognizer setDelegate:self];
    
    [self addGestureRecognizer:myPinchRecognizer];
    [self addGestureRecognizer:myRotateRecognizer];
}

-(void)doPeelAnimationForStix {
    
    int stixID = -1;
    for (int i=0; i<[auxStixStringIDs count]; i++) {
        UIImageView * peelStix = [auxStixViews objectAtIndex:i];
        CGPoint center = peelStix.center;
        if ([[auxStixStringIDs objectAtIndex:i] isEqualToString:stixPeelSelected] &&
            center.x == stixPeelSelectedCenter.x && center.y == stixPeelSelectedCenter.y) {
            stixID = i;
            break;
        }
    }
    if (stixID == -1)
        return;
    
    UIImageView * auxStix = [auxStixViews objectAtIndex:stixID];
    NSString * stixStringID = [auxStixStringIDs objectAtIndex:stixID];
    CGPoint center = [auxStix center];
    NSLog(@"Do peel animation: Stix %@ index %d frame %f %f", stixStringID, stixID, center.x, center.y);
    [auxStix setBackgroundColor:[UIColor clearColor]];
    [auxStix.layer removeAllAnimations];
    CGRect frameLift = auxStix.frame;
    frameLift.origin.x = center.x - frameLift.size.width / 2;
    frameLift.origin.y = center.y - frameLift.size.height / 2;
    
    CGAffineTransform transformLift = CGAffineTransformConcat(auxStix.transform, CGAffineTransformMakeScale(2.0, 2.0));
    [UIView transitionWithView:auxStix 
                      duration:.5
                       options:UIViewAnimationTransitionNone 
                    animations: ^ { 
#if 0
                        auxStix.frame = frameLift;
#else
                        [auxStix setTransform:transformLift];
#endif
                        
                        
                    } 
                    completion: ^ (BOOL finished) { 
                        CGRect frameDisappear = CGRectMake(160, 300, 5, 5);
                        [UIView transitionWithView:auxStix 
                                          duration:.25
                                           options:UIViewAnimationTransitionNone 
                                        animations: ^ { auxStix.frame = frameDisappear; } 
                                        completion:^(BOOL finished) { 
                                            [auxStix removeFromSuperview]; 
                                            isStillPeeling = NO;
                                            if ([delegate respondsToSelector:@selector(peelAnimationDidCompleteForStix:)])
                                                [delegate peelAnimationDidCompleteForStix:stixID]; 
                                        }
                         ];
                    }
     ];
}

-(void)transformBoxShowAtFrame:(CGRect)frame {
    [self transformBoxShowAtFrame:frame withTransform:CGAffineTransformIdentity];
}

-(void)transformBoxShowAtFrame:(CGRect)frame withTransform:(CGAffineTransform)t {
    if (transformCanvas) {
        [transformCanvas removeFromSuperview];
        transformCanvas = nil;
    }
    int canvasOffset = 5;
    if (!CGAffineTransformIsIdentity(t)) {
        CGPoint center; 
        center.x = frame.origin.x + frame.size.width / 2;
        center.y = frame.origin.y + frame.size.height / 2;
        UIImageView * basicStix = [self getStixWithStixStringID:selectStixStringID];
        [basicStix setCenter:center];
        frame = basicStix.frame;
    }    
    CGRect frameCanvas = frame;
    NSLog(@"frameCanvas: %f %f", frameCanvas.size.width, frameCanvas.size.height);
    frameCanvas.origin.x -= canvasOffset;
    frameCanvas.origin.y -= canvasOffset;
    frameCanvas.size.width += 2*canvasOffset;
    frameCanvas.size.height += 2*canvasOffset;
    transformCanvas = [[UIView alloc] initWithFrame:frameCanvas];
    [transformCanvas setAutoresizesSubviews:YES];
    frame.origin.x = canvasOffset;
    frame.origin.y = canvasOffset;
    CGRect frameInside = frame;
    NSLog(@"frameInside: %f %f", frameInside.size.width, frameInside.size.height);
    frameInside.origin.x +=1;
    frameInside.origin.y +=1;
    frameInside.size.width -= 2;
    frameInside.size.height -=2;
    UIImageView * transformBox = [[UIImageView alloc] initWithFrame:frameInside];
    transformBox.backgroundColor = [UIColor clearColor];
    transformBox.layer.borderColor = [[UIColor whiteColor] CGColor];
    transformBox.layer.borderWidth = 2.0;
    
    UIImageView * transformBoxShadow = [[UIImageView alloc] initWithFrame:frame];
    transformBoxShadow.backgroundColor = [UIColor clearColor];
    transformBoxShadow.layer.borderColor = [[UIColor blackColor] CGColor];
    transformBoxShadow.layer.borderWidth = 4.0;
    
    [transformCanvas addSubview:transformBoxShadow];
    [transformCanvas addSubview:transformBox];

    if (!CGAffineTransformIsIdentity(t))
        [transformCanvas setTransform:t];
    [self addSubview:transformCanvas];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"Touch!");
    if (interactionAllowed == NO) { // skips interaction with stix for dragging
        NSLog(@"interaction not allowed!");
        [super touchesBegan:touches withEvent:event];
        return;
    }
    NSLog(@"Touch allowed!");
    
    isTouch = 1;
    if (isDragging) // will come here if a second finger touches
        return;
	UITouch *touch = [[event allTouches] anyObject];	
	CGPoint location = [touch locationInView:self];
    
    /* TODO: enabling this seems to prevent touchesmoved
    if (bMultiStixMode) {
        // change current stix
        for (int i=0; i<[auxStixViews count]; i++) {
            UIImageView * currStix = [auxStixViews objectAtIndex:i];
            CGRect frame = currStix.frame;
            if (CGRectContainsPoint(frame, location)) {
                [self multiStixSelectCurrent:i];
                isTap = 1;
                // point where finger clicked badge
                offset_x = (location.x - stix.center.x);
                offset_y = (location.y - stix.center.y);
                
                break;
            }
        }
    }
     */
	isDragging = 0;
    CGRect frame = self.stix.frame;
    // add an allowance of touch
    int border = frame.size.width / 2;
    frame.origin.x -= border;
    frame.origin.y -= border;
    frame.size.width *= 2;
    frame.size.height *= 2;
    if (CGRectContainsPoint(frame, location))
    {
        isTap = 1;
        // point where finger clicked badge
        offset_x = (location.x - stix.center.x);
        offset_y = (location.y - stix.center.y);
        
    }
    
    NSLog(@"Touches began: center %f %f touch location %f %f", stix.center.x, stix.center.y, location.x, location.y);
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
     if (interactionAllowed == NO) {
        [super touchesMoved:touches withEvent:event];
        return;
    }

    isTouch = 0;
	if (isTap == 1 || isDragging == 1)
	{
        isDragging = 1;
        isTap = 0;
		UITouch *touch = [[event allTouches] anyObject];
		CGPoint location = [touch locationInView:self];
		// update frame of dragged badge, also scale
		//float scale = 1; // do not change scale while dragging
        
		float centerX = location.x - offset_x;
		float centerY = location.y - offset_y;
        
        // filter out rogue touches, usually when people are using a pinch
        if (abs(centerX - stix.center.x) > 50 || abs(centerY - stix.center.y) > 50) 
            return;
        if (centerX < 0 || centerX > self.frame.size.width || centerY < 0 || centerY > self.frame.size.height)
            return;
        
        stix.center = CGPointMake(centerX, centerY);
        if (transformCanvas) {
            [transformCanvas setCenter:stix.center];
        }
	}
    NSLog(@"Touches moved: new center %f %f", stix.center.x, stix.center.y);
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (interactionAllowed == NO) {
        [super touchesEnded:touches withEvent:event];
        return;
    }
    
    //NSLog(@"Touches ended: new center %f %f", stix.center.x, stix.center.y);

	if (isDragging == 1)
	{
        isDragging = 0;
        isTap = 0;
	}
    else if (isTap == 1 || isTouch == 1) {
        isTap = 0;
        isDragging = 0;
        isTouch = 0;
        
        if ([self.delegate respondsToSelector:@selector(didTouchInStixView:)])
            [self.delegate didTouchInStixView:self];
        
        if (bMultiStixMode) {
            UITouch *touch = [[event allTouches] anyObject];
            CGPoint location = [touch locationInView:self];

            // change current stix
            for (int i=0; i<[auxStixViews count]; i++) {
                UIImageView * currStix = [auxStixViews objectAtIndex:i];
                CGRect frame = currStix.frame;
                if (CGRectContainsPoint(frame, location)) {
                    [self multiStixSelectCurrent:i];
                    break;
                }
            }
        }
    }
}

/*** Gesture handlers ***/

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // enables recognizing two gestures at the same time
    return YES;
}

- (CGAffineTransform)applyRecognizer:(UIGestureRecognizer *)recognizer toTransform:(CGAffineTransform)transform
{
    if ([recognizer respondsToSelector:@selector(rotation)])
        return CGAffineTransformRotate(transform, [(UIRotationGestureRecognizer *)recognizer rotation]);
    else if ([recognizer respondsToSelector:@selector(scale)]) {
        CGFloat newscale = [(UIPinchGestureRecognizer *)recognizer scale];
        //if ((auxScale * newscale) > 3)
        //    newscale = 1;
        //auxScale = auxScale * newscale;
        return CGAffineTransformScale(transform, newscale, newscale);
    }
    else
        return transform;
}


-(void)doubleTapGestureHandler:(UITapGestureRecognizer*) gesture {
    // do nothing
    NSLog(@"Double tap!");
}

//-(void)pinchGestureHandler:(UIPinchGestureRecognizer*) gesture {
- (IBAction)handleGesture:(UIGestureRecognizer *)recognizer
{
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            if ([recognizer respondsToSelector:@selector(scale)]) {
                // scaling transform
                //NSLog(@"AuxView: Pinch motion started! scale %f velocity %f", [(UIPinchGestureRecognizer*)recognizer scale], [(UIPinchGestureRecognizer*)recognizer velocity]);
            }
            if (_activeRecognizers.count == 0)
                referenceTransform = stix.transform;
            [_activeRecognizers addObject:recognizer];
            break;
            
        case UIGestureRecognizerStateEnded:
            referenceTransform = [self applyRecognizer:recognizer toTransform:referenceTransform];
            [_activeRecognizers removeObject:recognizer];
            
            break;
            
        case UIGestureRecognizerStateChanged: {
            CGAffineTransform transform = referenceTransform;
            for (UIGestureRecognizer *recognizer in _activeRecognizers)
                transform = [self applyRecognizer:recognizer toTransform:transform];
            stix.transform = transform;
            
            if (transformCanvas)
            {
                transformCanvas.transform = transform;
            }
            break;
        }
            
        default:
            break;
    }
}

-(bool)isForeground:(CGPoint)point inStix:(UIImageView*)selectedStix {
    BOOL isForeground = NO;
    int dx=0;
    int dy=0;
    //for (int dx = -3; dx < 3; dx++) {
    //    for (int dy = -3; dy < 3; dy++) {
    
    unsigned char pixel[1] = {0};
    CGContextRef context = CGBitmapContextCreate(pixel, 
                                                 1, 1, 8, 1, NULL,
                                                 kCGImageAlphaOnly);
    UIGraphicsPushContext(context);
    UIImage * im = selectedStix.image;
    // convert - the point coordinates goes from 0-78 - convert point to view uses original stix UIImageView frame
    // the image size varies - size of im could be 120x120, 240x240, etc
    CGSize size = im.size;
    float scale = size.width / (120 * .65);
    point.x *= scale; // convert to the UIImage size
    point.y *= scale; 
    [im drawAtPoint:CGPointMake(-point.x + dx, -point.y + dy)];
    UIGraphicsPopContext();
    CGContextRelease(context);
    CGFloat alpha = pixel[0]/255.0;
    BOOL thisTransparent = alpha < 0.1;
    if (!thisTransparent) {
        isForeground = YES;
    }
    NSLog(@"Foreground test: x y %f %f, pixel %d alpha %f foreGround %d", point.x + dx, point.y + dy, pixel[0], alpha, isForeground);
    //    }
    // }
    return isForeground;
}

//-(void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
//}
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // button index: 0 = "Peel", 1 = "Stick", 2 = "Move", 3 = "Cancel"
    //NSLog(@"Button index: %d stixPeelSelected: %d", buttonIndex, stixPeelSelected);
    switch (buttonIndex) {
        case 0: // Peel
            // performing a peel action causes this StixView and its delegate FeedItemView to eventually be deleted/removed. Until that happens and the user interface is correctly populated, do not allow interaction anymore.
            //self.isPeelable = NO;
            
            isStillPeeling = YES;
            // remove from delegate's tag structure
            //if ([self.delegate respondsToSelector:@selector(didPeelStix:)])
                //[self.delegate didPeelStix:stixPeelSelected];
            [self doPeelAnimationForStix];    
            break;
        case 1: // Stick
            /*
            //self.isPeelable = NO;
            if ([self.delegate respondsToSelector:@selector(didAttachStix:)])
                [self.delegate didAttachStix:stixPeelSelected]; // will cause new StixView to be created
             */
            break;
        case 2: // Cancel
            return;
            break;
        default:
            return;
            break;
    }
}

#pragma mark Multi stix mode

-(int)multiStixInitializeWithTag:(Tag *)tag useStixLayer:(BOOL)useStixLayer {
    if (auxStixViews == nil) {
        auxStixViews = [[NSMutableArray alloc] init];
        auxStixStringIDs = [[NSMutableArray alloc] init];
    }
    
    // clear all existing stix in the stixview
    for (int i=0; i<[auxStixViews count]; i++) {
        UIView * subview = [auxStixViews objectAtIndex:i];
        [subview removeFromSuperview];
    }
    if (transformCanvas) {
        [transformCanvas removeFromSuperview];
        transformCanvas = nil;
    }
    [auxStixViews removeAllObjects];
    [auxStixStringIDs removeAllObjects];
    
    tagUsername = [[tag username] copy];
    tagID = tagID;

    if (useStixLayer) {
        // add stix layer
        CGSize newSize = self.frame.size;
        UIGraphicsBeginImageContext(newSize);
        CGRect fullFrame = CGRectMake(0, 0, newSize.width, newSize.height);
        [tag.image drawInRect:fullFrame];	
        [tag.stixLayer drawInRect:fullFrame];
        UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();	
        
        UIImageView * srcImageView = [[UIImageView alloc] initWithImage:result];
        [self addSubview:srcImageView];
    }
    
    // add pinch and rotate gesture recognizer
    UIPinchGestureRecognizer * myPinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)]; //(pinchGestureHandler:)];
    [myPinchRecognizer setDelegate:self];
    
    UIRotationGestureRecognizer *myRotateRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)]; //(pinchRotateHandler:)];
    [myRotateRecognizer setDelegate:self];
    
    [self addGestureRecognizer:myPinchRecognizer];
    [self addGestureRecognizer:myRotateRecognizer];   
    
    bMultiStixMode = YES;
    multiStixCurrent = -1;
    interactionAllowed = YES;
    
    NSLog(@"MultiStix initialize with tag with %d auxStix", [auxStixViews count]);
    
    return YES;
}

// this function creates a temporary stix object that can be manipulated
-(void)multiStixAddStix:(NSString*)stixStringID atLocationX:(int)x andLocationY:(int)y /*andScale:(float)scale andRotation:(float)rotation */{
    NSLog(@"Adding stix %@ to %d %d", stixStringID, x, y);
    CGRect frame = self.frame;
    frame.origin.x = 0;
    frame.origin.y = 0;
    
    referenceTransform = CGAffineTransformIdentity;
    
    [self setSelectStixStringID:stixStringID];
    self.stix = [self getStixWithStixStringID:selectStixStringID];
    float centerX = x;
    float centerY = y;

	CGRect stixFrameScaled = stix.frame;

    [self.stix setFrame:stixFrameScaled];
    [self.stix setCenter:CGPointMake(centerX, centerY)];
    [self.stix setAlpha:0];
    [self addSubview:self.stix];
    StixAnimation * animation = [[StixAnimation alloc] init];
    //[animation doFade:stix inView:self toAlpha:1 forTime:.25];
    [animation doFadeIn:self.stix forTime:1 withCompletion:^(BOOL finished) {
        showTransformCanvas = YES;
        [self transformBoxShowAtFrame:self.stix.frame];
        
        [self multiStixSelectCurrent:[auxStixViews count]];
    }];
}

-(void)multiStixSelectCurrent:(int)stixIndex {
    NSLog(@"MultiStixSelectCurrent: currently editing %d, changing to index %d, total existing %d auxStix", multiStixCurrent, stixIndex, [auxStixViews count]);
    if (stixIndex == -1)
        return;
    
    // if a stix is already being manipulated, make sure to sync it with auxStix
    if (multiStixCurrent == -1) {
        // currently selected stix was a new stix; needs to be added to auxStix
        if (selectStixStringID) {      
            // only if a stix was actually added
            [auxStixViews addObject:stix];
            [auxStixStringIDs addObject:selectStixStringID];
        }
    }
    else {
        if (stix) {
            // currently selected stix is an existing stix; sync
            if (stixIndex < [auxStixViews count]) {
                // replace
                [auxStixViews replaceObjectAtIndex:multiStixCurrent withObject:stix];            
            }
            else if (stixIndex == [auxStixViews count]) {
                // add
                [auxStixViews addObject:stix];
                [auxStixStringIDs addObject:selectStixStringID];
            }
        }
    }
    
    stix = [auxStixViews objectAtIndex:stixIndex];
    selectStixStringID = [auxStixStringIDs objectAtIndex:stixIndex];
    multiStixCurrent = stixIndex;
    //referenceTransform = stix.transform;
    
    NSLog(@"Switching to stix at index %d with frame %f %f %f %f and transform %@", stixIndex, stix.frame.origin.x, stix.frame.origin.y, stix.frame.size.width, stix.frame.size.height, NSStringFromCGAffineTransform( stix.transform ) );
    
    [self transformBoxShowAtFrame:stix.frame withTransform:stix.transform];
}

-(int) multiStixDeleteCurrentStix {
    if (transformCanvas) {
        [transformCanvas removeFromSuperview];
        transformCanvas = nil;
    }
    if (multiStixCurrent != -1) {
        stix = nil;
        selectStixStringID = nil;
        if (multiStixCurrent < [auxStixViews count]) {
            [[auxStixViews objectAtIndex:multiStixCurrent] removeFromSuperview];
            [auxStixViews removeObjectAtIndex:multiStixCurrent];
            [auxStixStringIDs removeObjectAtIndex:multiStixCurrent];
        }
        //multiStixCurrent = -1;
        [self multiStixSelectCurrent:[auxStixViews count]-1];
    } else {
        if (stix) {
            [stix removeFromSuperview];
            stix = nil;
            selectStixStringID = nil;
        }
    }
    return [auxStixStringIDs count];
}

-(void) multiStixClearAllStix {
    if ([auxStixViews count] > 0) {
        for (int i=0; i<[auxStixViews count]; i++) {
            stix = [auxStixViews objectAtIndex:i];
            [stix removeFromSuperview];
        }
        [auxStixViews removeAllObjects];
        [auxStixStringIDs removeAllObjects];
    }
    if (stix) {
        [stix removeFromSuperview];
        stix = nil;
        selectStixStringID = nil;
    }
    if (transformCanvas) {
        [transformCanvas removeFromSuperview];
        transformCanvas = nil;
    }
}
@end
