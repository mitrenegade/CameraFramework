//
//  FBHelper.h
//  Camera Framework App
//
//  Created by Bobby Ren on 2/15/13.
//  Copyright (c) 2013 Neroh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>

@protocol FBHelperDelegate <NSObject>

-(void)didOpenSession;
-(void)didGetPublishPermissions;
-(void)didFailOpen;
@end

@interface FBHelper : NSObject

@property (nonatomic, weak) id delegate;

-(void)openSession;
-(void)requestPublish;
@end

