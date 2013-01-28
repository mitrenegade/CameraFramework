//
//  StickerPanelViewController.m
//  Camera Framework App
//
//  Created by Bobby Ren on 1/27/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import "StickerPanelViewController.h"

@implementation StickerPanelViewController

@synthesize scrollView;
@synthesize photoView;
@synthesize  allStickerViews;
@synthesize delegate;

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)initWithImage:(UIImage *)newImage {
    [self.photoView setImage:newImage];
}

-(void)reloadAllStickers {
    NSArray * stickerFilenames = @[STIX_FILENAMES];
    
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Stickers" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    
    int stixWidth = STIX_SIZE + 10;
    int stixHeight = STIX_SIZE + 20;
    
    int ct = 0;
    for (NSString * filename in stickerFilenames) {
        NSString * imageName = [bundle pathForResource:filename ofType:@"png"];
        UIImage * img = [[UIImage alloc] initWithContentsOfFile:imageName];
        UIImageView * stickerImage = [[UIImageView alloc] initWithImage:img];
        [stickerImage setTag:ct];
        
        CGRect frame = CGRectMake(0, 0, STIX_SIZE, STIX_SIZE);
        [stickerImage setFrame:frame];

        int row = ct / STIX_PER_ROW;
        int col = ct - row * STIX_PER_ROW;
        CGPoint stixCenter = CGPointMake(stixWidth*col + stixWidth / 2, stixHeight*row + stixHeight/2);
        [stickerImage setCenter:stixCenter];
        [self.scrollView addSubview:stickerImage];
        [self.allStickerViews addObject:stickerImage];
        
        //NSLog(@"Adding sticker %d to panel: %@ frame %f %f %f %f", ct, imageName, stickerImage.frame.origin.x, stickerImage.frame.origin.y, stickerImage.frame.size.width, stickerImage.frame.size.height);
        ct++;
    }
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

-(IBAction)didClickSave:(id)sender {
    NSLog(@"Saving!");
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
}
@end

