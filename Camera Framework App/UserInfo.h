//
//  UserInfo.h
//  CrowdDynamics
//
//  Created by Bobby Ren on 8/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ParseUserInfo.h"

@class UserPulse;

@interface UserInfo : ParseUserInfo

@property (strong, nonatomic) NSString * className;
@property (strong, nonatomic) NSString * username;
@property (strong, nonatomic) NSString * password;
@property (strong, nonatomic) NSString * email;

@property (strong, nonatomic) UIImage * photo;
@property (strong, nonatomic) NSString * photoURL;

@property (strong, nonatomic) NSString * pfUserID;

+(void)FindUserInfoFromParse:(UserInfo*)userInfo withBlock:(void (^)(UserInfo *, NSError *))queryCompletedWithResults;
+(void)UpdateUserInfoToParse:(UserInfo*)userInfo;

// new login
+(void)GetUserInfoForPFUser:(PFUser*)pfUser withBlock:(void (^)(UserInfo *, NSError *))queryCompletedWithResults;

-(void)savePhotoToAWS:(UIImage*)newPhoto withBlock:(void (^)(BOOL))photoSaved;
-(void)savePhotoToAWSWithURL:(NSString*)photoURL withNameKey:(NSString*)nameKey withBlock:(void (^)(BOOL))photoSaved;

@end
