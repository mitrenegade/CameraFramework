//
//  PreviewController.h
//  Camera Framework App
//
//  Created by Bobby Ren on 1/4/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PreviewController : UIViewController <UINavigationControllerDelegate>
{
    IBOutlet UIButton * buttonNext;
}

-(IBAction)didClickNextButton:(id)sender;

@end