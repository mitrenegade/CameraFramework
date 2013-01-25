//
//  GenericRefreshViewController.h
//  Camera Framework App
//
//  Created by Bobby Ren on 1/23/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParseHelper.h"

@interface GenericRefreshViewController : UIViewController <PF_EGORefreshTableHeaderDelegate, UITableViewDataSource, UITableViewDelegate>
{
    PF_EGORefreshTableHeaderView *refreshHeaderView;
    BOOL _reloading;
}
@property (nonatomic, weak) IBOutlet UITableView * tableView;

@end
