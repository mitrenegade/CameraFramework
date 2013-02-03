//
//  ParseTag.m
//  Stixx
//
//  Created by Bobby Ren on 11/5/12.
//
//

#import "ParseTag.h"

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

-(PFObject*)toPFObject {
    // for a pulse we only need to save the pfUser and the location
    
    PFObject *newObject = [[PFObject alloc] initWithClassName:CLASSNAME];
    
//    [newObject setObject:pfUser forKey:@"pfUser"];
//    [newObject setObject:pfUserID forKey:@"pfUserID"];
    NSLog(@"Saving image of size %f %f", image.size.width, image.size.height);
    //[newObject setObject:UIImageJPEGRepresentation(image, .8) forKey:@"imageData"];
    //[newObject setObject:UIImagePNGRepresentation(stixLayer) forKey:@"stixLayerData"];
    [newObject setObject:username forKey:@"username"];
    
    return newObject;
}

- (id)fromPFObject:(PFObject *)pObject {
//    [self setClassName:pObject.className];
//    [self setPfUser:[pObject objectForKey:@"pfUser"]];
//    [self setPfUserID:[pObject objectForKey:@"pfUserID"]];
    [self setPfObject:pObject];
    //[self setImage:[UIImage imageWithData:[pObject objectForKey:@"imageData"]]];
    //[self setStixLayer:[UIImage imageWithData:[pObject objectForKey:@"stixLayerData"]]];
    [self setUsername:[pObject objectForKey:@"username"]];
    
    [self setImageURL:[pObject objectForKey:@"imageURL"]];
    [self setHighResImage:[pObject objectForKey:@"highResImageURL"]];
    [self setStixLayerURL:[pObject objectForKey:@"stixLayerURL"]];
    [self setThumbnailURL:[pObject objectForKey:@"thumbnailURL"]];
    return self;
}
/*
-(id)initWithTag:(Tag *)tag {
    self = [super init];
    if (self)
    {
        self.username = tag.username;
        self.image = tag.image;
        self.stixLayer = tag.stixLayer;
        self.highResImage = tag.highResImage;
        self.thumbnail = tag.thumbnail;
    }
    return self;
}

-(Tag*)toTag {
    Tag * tag = [[Tag alloc] init];
    tag.username = self.username;
    //tag.image = self.image;
    //tag.stixLayer = self.stixLayer;
    //tag.highResImage = self.highResImage;
    tag.timestamp = [self.pfObject createdAt];
    tag.pfObjectID = [self.pfObject objectId];
    tag.imageURL = [self getImageURL];
    tag.stixLayerURL = [self getStixLayerURL];
    tag.highResImageURL = [self getHiResImageURL];
    tag.thumbnailURL = [self getThumbnailURL];
    return tag;
}

+(void)getTagAfterTimestamp:(NSDate*)timestamp totalTags:(int)count withCompletion:(PFArrayResultBlock)queryCompletedWithResults{
    PFCachePolicy policy = kPFCachePolicyNetworkOnly; //kPFCachePolicyCacheElseNetwork;
    PFQuery * query = [PFQuery queryWithClassName:CLASSNAME];
    [query setCachePolicy:policy];
    if (!timestamp) {
        timestamp = [NSDate date];
        //queryCompletedWithResults(NO, nil);
    }
    
    [query whereKey:@"createdAt" greaterThan:timestamp];
    [query setLimit:count];
    [query orderByDescending:@"createdAt"];
    [query findObjectsInBackgroundWithBlock:queryCompletedWithResults];
}

+(void)getTagBeforeTimestamp:(NSDate*)timestamp totalTags:(int)count withCompletion:(PFArrayResultBlock)queryCompletedWithResults{
    PFCachePolicy policy = kPFCachePolicyNetworkOnly; //kPFCachePolicyCacheElseNetwork;
    PFQuery * query = [PFQuery queryWithClassName:CLASSNAME];
    [query setCachePolicy:policy];
    NSLog(@"Querying for class: %@", CLASSNAME);
    NSLog(@"Updated at %@", timestamp);
    if (!timestamp) {
        timestamp = [NSDate date];
        //queryCompletedWithResults(NO, nil);
    }
    else {
        [query whereKey:@"createdAt" lessThan:timestamp];
        [query setLimit:count];
        [query orderByDescending:@"createdAt"];
        [query findObjectsInBackgroundWithBlock:queryCompletedWithResults];
    }
}
*/

-(void)uploadWithBlock:(void (^)(NSString *, BOOL))uploadDidComplete {
    PFObject * pfObject = [self toPFObject];
    [self setPfObject:pfObject];
    
    [ParseHelper addParseObjectToParse:pfObject withBlock:^(BOOL didfinish, NSError * error) {
        //NSNumber * newRecordID = [NSNumber numberWithInt:0];
        //NSMutableArray * returnParams = [NSMutableArray arrayWithObjects:newRecordID, newTag, remixMode, nil];
        NSLog(@"Uploaded parse image! pfObject has id: %@", pfObject.objectId);
        //[parseObject refresh];
        //NSLog(@"Refreshed parse image! pfObject has id: %@", parseObject.objectId);
        NSString * objectID = pfObject.objectId;
        uploadDidComplete(objectID, YES);

        // do the rest in background
        [AWSHelper uploadImage:self.image withName:objectID toBucket:IMAGE_URL_BUCKET withCallback:^(NSString * newURL) {
            // do not save imageURL - this is generated from bucket and objectID each time
            /*
             NSLog(@"Image for object %@ saved at %@", objectID, newURL);
            self.imageURL = newURL;
            NSString * key = @"imageURL";
            [ParseHelper updateParseObject:pfObject withNewValue:newURL forKey:key withBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    NSLog(@"Updated object with objectID %@ with new value %@ for key %@", pfObject.objectId, newURL, key);
                }
                else {
                    NSLog(@"Update parse object for objectID %@ with newValue %@ could not complete! Error: %@", pfObject.objectId, newURL, error.description);
                }
            }];
             */
        }];
        if (self.highResImage) {
            [AWSHelper uploadImage:self.highResImage withName:objectID toBucket:HIRES_IMAGE_URL_BUCKET withCallback:^(NSString * newURL) {
                // do not save imageURL - this is generated from bucket and objectID each time
                /*
                NSLog(@"High res image saved at %@", newURL);
                self.highResImageURL = newURL;
                NSString * key = @"highResImageURL";
                [ParseHelper updateParseObject:pfObject withNewValue:newURL forKey:key withBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        NSLog(@"Updated object with objectID %@ with new value %@ for key %@", pfObject.objectId, newURL, key);
                    }
                    else {
                        NSLog(@"Hires image for objectID %@ could not be uploaded", pfObject.objectId);
                    }
                }];
                 */
            }];
        }
        if (self.stixLayer) {
            [AWSHelper uploadImage:self.stixLayer withName:objectID toBucket:STIXLAYER_IMAGE_URL_BUCKET withCallback:^(NSString * newURL) {
                // do not save imageURL - this is generated from bucket and objectID each time
                /*
                NSLog(@"Stix layer saved at %@", newURL);
                self.stixLayerURL = newURL;
                NSString * key = @"stixLayerURL";
                [ParseHelper updateParseObject:pfObject withNewValue:newURL forKey:key withBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        NSLog(@"Updated object with objectID %@ with new value %@ for key %@", pfObject.objectId, newURL, key);
                    }
                    else {
                        NSLog(@"Stix layer for objectID %@ could not be uploaded", pfObject.objectId);
                    }
                }];
                 */
            }];
        }
        if (self.thumbnail) {
            [AWSHelper uploadImage:self.thumbnail withName:objectID toBucket:THUMBNAIL_IMAGE_URL_BUCKET withCallback:^(NSString * newURL) {
            }];
        }
    }];
}

-(NSString*)getImageURL {
    return [AWSHelper getURLForKey:self.pfObject.objectId inBucket:IMAGE_URL_BUCKET];
}
-(NSString*)getHiResImageURL {
    return [AWSHelper getURLForKey:[NSString stringWithFormat:@"%@", self.pfObject.objectId] inBucket:HIRES_IMAGE_URL_BUCKET];
}
-(NSString*)getStixLayerURL {
    return [AWSHelper getURLForKey:[NSString stringWithFormat:@"%@", self.pfObject.objectId] inBucket:STIXLAYER_IMAGE_URL_BUCKET];
}
-(NSString*)getThumbnailURL {
    return [AWSHelper getURLForKey:[NSString stringWithFormat:@"%@", self.pfObject.objectId] inBucket:THUMBNAIL_IMAGE_URL_BUCKET];
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