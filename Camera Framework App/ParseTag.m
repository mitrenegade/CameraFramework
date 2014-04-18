//
//  ParseTag.m
//  Stixx
//
//  Created by Bobby Ren on 11/5/12.
//
//

#import "ParseTag.h"
#import "Flurry.h"

@implementation ParseTag

#define CLASSNAME @"StixTag"

//@synthesize pfObject, pfUser, pfUserID;
@synthesize image, username, stixLayer, highResImage, thumbnail;
@synthesize imageURL, stixLayerURL, highResImageURL, thumbnailURL;

- (id)initWithPFObject:(PFObject *)object {
    self = [super init];
    if (self)
    {
        [self fromPFObject:object];
    }
    return self;
}

- (id)fromPFObject:(PFObject *)pObject {
    [self setPfObject:pObject];
    [self setUsername:[pObject objectForKey:@"username"]];
    
    [self setImageURL:[pObject objectForKey:@"imageURL"]];
    [self setHighResImage:[pObject objectForKey:@"highResImageURL"]];
    [self setStixLayerURL:[pObject objectForKey:@"stixLayerURL"]];
    [self setThumbnailURL:[pObject objectForKey:@"thumbnailURL"]];
    return self;
}

-(void)saveOrUpdateToParseWithCompletion:(void (^)(BOOL))completion {
    if (!self.pfObject) {
        self.pfObject = [PFObject objectWithClassName:self.className];
        PFACL *readWriteACL = [PFACL ACL];
        [readWriteACL setPublicReadAccess:YES]; // Create read-write permissions
        [readWriteACL setWriteAccess:YES forUser:[PFUser currentUser]];
        [readWriteACL setPublicWriteAccess:NO];
        [self.pfObject setACL:readWriteACL]; // Set the permissions on the postObject
    }

    if (username)
        [self.pfObject setObject:username forKey:@"username"];
    self.pfObject[@"app"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
	NSString *version =  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    [self.pfObject setObject:version forKey:@"version"];

    if (self.thumbnail) {
        [self saveImage:self.thumbnail key:@"thumbnail" completion:^(BOOL succeeded, NSError *error) {
            completion(succeeded);
        }];
    }
    else {
        if (completion)
            completion(YES);
    }

    if (self.image) {
        [self saveImage:self.image key:@"image" completion:^(BOOL succeeded, NSError *error) {
        }];
    }

    if (self.highResImage) {
        [self saveImage:self.highResImage key:@"highResImage" completion:^(BOOL succeeded, NSError *error) {

        }];
    }
}

-(void)saveImage:(UIImage *)img key:(NSString *)key completion:(void(^)(BOOL succeeded, NSError *error))completion {
    // key is the parse object reference key
    [Flurry logEvent:@"PARSE IMAGE UPLOAD" timed:YES];
    NSData *data = UIImageJPEGRepresentation(img, .8);
    PFFile *imageFile = [PFFile fileWithData:data];
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        NSLog(@"Image done!");
        self.pfObject[key] = imageFile;
        [self.pfObject saveEventually:^(BOOL succeeded, NSError *error) {
            NSLog(@"Parse image upload for key %@ %d", key, succeeded);
            if (error)
                NSLog(@"Image upload error: %@", error);
            [Flurry endTimedEvent:@"PARSE IMAGE UPLOAD" withParameters:nil];

            if (completion)
                completion(succeeded, error);
        }];
    } progressBlock:^(int percentDone) {
        NSLog(@"image upload key %@ %d done", key, percentDone);
    }];
}

-(void)addRelation:(NSString*)relation withUser:(PFUser *)user withBlock:(void (^)(BOOL succeeded, NSError *))addRelationResults {
    // relations must operate on pfObjects
    // we need two pfObjects of type UserInfo
    // so we have to use the pfObject stored in user1 and user2
    
    if (!user) {
        NSLog(@"No pfObject! must query from web...");
    }
    else if (!self.pfObject) {
        NSLog(@"ParseTag does not have pfObject! Must save tag first.");
    }
    else {
        PFRelation * relations = [self.pfObject relationforKey:relation];
        [relations addObject:user];
        [self.pfObject saveEventually:^(BOOL succeeded, NSError *error) {
            if (addRelationResults)
                addRelationResults(succeeded, error);
        }];
    }
}
@end
