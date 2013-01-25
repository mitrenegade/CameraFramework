//
//  ProfileViewController.h
//  Camera Framework App
//
//  Created by Bobby Ren on 1/23/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"
#import "UserInfo.h"

@interface ProfileViewController : UIViewController <PF_EGORefreshTableHeaderDelegate>
{
    PF_EGORefreshTableHeaderView *refreshHeaderView;
    BOOL _reloading;
}
@property (nonatomic, weak) IBOutlet UITableView * tableView;

@property (weak, nonatomic) IBOutlet AsyncImageView * photoView;
@property (weak, nonatomic) IBOutlet UILabel * nameLabel;
@property (nonatomic, weak) UserInfo * myUserInfo;

@end
