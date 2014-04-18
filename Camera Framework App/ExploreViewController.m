//
//  ExploreViewController.m
//  Camera Framework App
//
//  Created by Bobby Ren on 3/29/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import "ExploreViewController.h"
#import <Parse/Parse.h>
#import "AsyncImageView.h"
#import "ParseTag.h"

@interface ExploreViewController ()

@end

@implementation ExploreViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(dismissModalViewControllerAnimated:)];
    
    pfObjectArray = [[NSMutableArray alloc] init];
    [self loadMore:[NSDate date]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSLog(@"Images to explore: %d", [pfObjectArray count]);
    return [pfObjectArray count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGSize thumbSize = CGSizeMake(96, 155);
    return thumbSize.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    for (UIView * subview in cell.contentView.subviews)
         [subview removeFromSuperview];

    CGSize thumbSize = CGSizeMake(96, 155);
    AsyncImageView * imageView = [[AsyncImageView alloc] initWithFrame:CGRectMake(0, 0, thumbSize.width, thumbSize.height)];
    PFObject * object = [pfObjectArray objectAtIndex:indexPath.row];
    NSString * pfObjectID = object.objectId;
	NSString *version =  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

    PFFile *imageFile = object[@"thumbnail"];
    [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            UIImage *img = [UIImage imageWithData:data];
            [imageView setImage:img];
        }
    }];
    [cell.contentView addSubview:imageView];
    
    if (indexPath.row == [pfObjectArray count] - 1) {
        // reached last row, load more
        NSDate * lastDate = object.createdAt;
        [self loadMore:lastDate];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    return;
    
    CGRect frame = self.view.frame;
    AsyncImageView * imageView = [[AsyncImageView alloc] initWithFrame:frame];
    PFObject * object = [pfObjectArray objectAtIndex:indexPath.row];
    NSString * pfObjectID = object.objectId;
	NSString *version =  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    PFFile *imageFile = object[@"thumbnail"];
    [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            UIImage *img = [UIImage imageWithData:data];
            [imageView setImage:img];
        }
    }];

    UIViewController * viewController = [[UIViewController alloc] init];
    [viewController.view setBackgroundColor:[UIColor whiteColor]];
    [viewController.view addSubview:imageView];
    [self.navigationController pushViewController:viewController animated:YES];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

-(void)loadMore:(NSDate*)date {
    NSString * className = @"ParseTag";
    PFQuery * query = [PFQuery queryWithClassName:className];
    [query whereKey:@"createdAt" lessThan:date];
    [query orderByDescending:@"createdAt"];
    query.limit = 10;
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            [pfObjectArray addObjectsFromArray:objects];
            NSLog(@"Loaded %d objects, total objects %d", [objects count], [pfObjectArray count]);
        }
        if ([objects count])
            [self.tableView reloadData];
    }];
}

@end
