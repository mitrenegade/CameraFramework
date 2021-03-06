//
//  UserInfo.m
//  CrowdDynamics
//
//  Created by Bobby Ren on 8/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserInfo.h"
#import "Constants.h"

@implementation UserInfo
@synthesize username, password, email;
@synthesize photo;
@synthesize photoURL;
@synthesize pfUser;
@synthesize pfUserID;
@synthesize pfObject;
@synthesize className;

#define CLASSNAME @"UserInfo"

-(id)init {
    self = [super init];
    [self setClassName:CLASSNAME];
    // if we init a userInfo, it must have a new/empty pfObject
    // userInfo objects created from Parse are generated by initWithPFObject which uses fromPFObject
    PFObject *newPFObject = [[PFObject alloc] initWithClassName:CLASSNAME];
    [self setPfObject:newPFObject];
    return self;
}

-(PFObject*)pfObject {
    // returns current object
    if (pfObject)
        return pfObject;
    else {
        // do not allocate; returning nil should indicate need to find object
        return nil;
    }
    return pfObject;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject: username forKey:@"username"];
    [aCoder encodeObject: password forKey:@"password"];
    [aCoder encodeObject: email forKey:@"email"];
    [aCoder encodeObject: UIImagePNGRepresentation(photo) forKey:@"photoData"];
    [aCoder encodeObject: UIImagePNGRepresentation(photo) forKey:@"photoBlurData"];
    [aCoder encodeObject:pfUserID forKey:@"pfUserID"];
}

-(id)initWithCoder:(NSCoder *)aDecoder {    
    
    if ((self = [super initWithCoder:aDecoder])) {
        [self setUsername:[aDecoder decodeObjectForKey:@"username"]];
        [self setPassword:[aDecoder decodeObjectForKey:@"password"]];
        [self setEmail:[aDecoder decodeObjectForKey:@"email"]];
        [self setPhoto:[UIImage imageWithData:[aDecoder decodeObjectForKey:@"photoData"]]];
        [self setPfUserID:[aDecoder decodeObjectForKey:@"pfUserID"]];
    }
    return self;
}

- (PFObject *)toPFObject {
    //PFObject *junctionPFObject = [[PFObject alloc] initWithClassName:@"UserInfo"];
    @try {
        if (username)
            [self.pfObject setObject:username forKey:@"username"];
        if (password)
            [self.pfObject setObject:password forKey:@"password"];
        if (email)
            [self.pfObject setObject:email forKey:@"email"];
        // don't save photo data, and don't save url because amazon urls expire
        if (pfUserID)
            [self.pfObject setObject:pfUserID forKey:@"pfUserID"];
        if (pfUser)
            [self.pfObject setObject:pfUser forKey:@"pfUser"];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception in UserInfo.toPFObject! %@", exception.description);
        return nil;
    }
    
    NSLog(@"Created new UserInfo for user %@ pfUserID %@", username, pfUserID);
    
    return self.pfObject;
}

- (id)fromPFObject:(PFObject *)obj {
    [self setPfObject:obj];
    
    username = [obj objectForKey:@"username"];
    password = [obj objectForKey:@"password"];
    email = [obj objectForKey:@"email"];
    pfUserID = [obj objectForKey:@"pfUserID"];
    pfUser = [obj objectForKey:@"pfUser"];
    
    return [super fromPFObject:obj];
}

+(void)FindUserInfoFromParse:(UserInfo*)userInfo withBlock:(void (^)(UserInfo *, NSError *))queryCompletedWithResults{
    PFCachePolicy policy = kPFCachePolicyNetworkOnly;
    PFQuery * query = [PFQuery queryWithClassName:CLASSNAME];
    [query setCachePolicy:policy];
    
    PFUser * pfUser = userInfo.pfUser;
    if (pfUser) {
        NSLog(@"FindUserInfo using pfUser");
        // add user constraint
        [query whereKey:@"pfUser" equalTo:pfUser];
    }
    else if (userInfo.pfUserID) {
        NSString * pfUserID = userInfo.pfUserID;
        NSLog(@"FindUserInfo using pfUserID %@", pfUserID);
        // add user constraint
        [query whereKey:@"pfUserID" equalTo:pfUserID];
    }
    /*
    else if (userInfo.linkedInString) {
        NSString * linkedInString = userInfo.linkedInString;
        NSLog(@"FindUserInfo using linkedInString %@", linkedInString);
        // add user constraint
        [query whereKey:@"linkedInString" equalTo:linkedInString];
    }
     */
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"FindUserInfoFromParse: Query resulted in error!");
            queryCompletedWithResults(nil, error);
        }
        else {
            if ([objects count] == 0) {
                NSLog(@"FindUserInfoFromParse: 0 results");
                queryCompletedWithResults(nil, nil);
            }
            else {
                PFObject * object = [objects objectAtIndex:0];
                [userInfo setPfObject:object];
                queryCompletedWithResults(userInfo, error);
            }
        }
    }];

}

+(void)UpdateUserInfoToParse:(UserInfo*)userInfo {
    [UserInfo FindUserInfoFromParse:userInfo withBlock:^(UserInfo * result, NSError * error) {
        if (result) {
            PFObject * pfObject = [result toPFObject];
            [pfObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    NSLog(@"UpdateUserInfoToParse Saving userInfo %@ succeeded", userInfo);
                }
                else {
                    NSLog(@"UpdateUserInfoToParse error: %@", error);
                }
            }];
        }
        else {
            NSLog(@"UpdateUserInfoToParse Error finding userInfo on Parse!");
        }
    }];
}

// new login
+(void)GetUserInfoForPFUser:(PFUser*)pfUser withBlock:(void (^)(UserInfo *, NSError *))queryCompletedWithResults{
    PFCachePolicy policy = kPFCachePolicyNetworkOnly;
    PFQuery * query = [PFQuery queryWithClassName:CLASSNAME];
    [query setCachePolicy:policy];
    [query whereKey:@"pfUser" equalTo:pfUser];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"FindUserInfoFromParse: Query resulted in error!");
            queryCompletedWithResults(nil, error);
        }
        else {
            if ([objects count] == 0) {
                NSLog(@"FindUserInfoFromParse: 0 results");
                queryCompletedWithResults(nil, nil);
            }
            else {
                PFObject * object = [objects objectAtIndex:0];
                UserInfo * userInfo = [[UserInfo alloc] initWithPFObject:object];
                queryCompletedWithResults(userInfo, error);
            }
        }
    }];
    
}

-(void)savePhotoToAWS:(UIImage*)newPhoto withBlock:(void (^)(BOOL))photoSaved {
    // AWSHelper uploadImage must always be on main thread!
    NSString * name =[NSString stringWithFormat:@"%@", self.username];
    if (newPhoto) {
        NSData *data = UIImageJPEGRepresentation(newPhoto, .8);
        PFFile *imageFile = [PFFile fileWithData:data];
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            self.photo = newPhoto;
            photoSaved(YES);
        }];
    }
}

-(void)savePhotoToAWSWithURL:(NSString*)photoURL withNameKey:(NSString*)nameKey withBlock:(void (^)(BOOL))photoSaved {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        UIImage * newPhoto = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:photoURL]]];
        // AWSHelper uploadImage must always be on main thread!
        dispatch_async(dispatch_get_main_queue(), ^{
            NSData *data = UIImageJPEGRepresentation(newPhoto, .8);
            PFFile *imageFile = [PFFile fileWithData:data];
            [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                self.photo = newPhoto;
                photoSaved(YES);
            }];
        });
    });
}

@end
