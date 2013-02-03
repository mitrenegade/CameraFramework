//
//  ParseTag.h
//  Stixx
//
//  Created by Bobby Ren on 11/5/12.
//
//

#import <Foundation/Foundation.h>
#import "PFObjectFactory.h"
//#import "Tag.h"
#import "ParseHelper.h"
#import "AWSHelper.h"

@interface ParseTag : NSObject <PFObjectFactory>

//@property (nonatomic) PFUser * pfUser;
@property (nonatomic) PFObject * pfObject;
//@property (nonatomic) NSString * pfUserID;
@property (nonatomic) NSString * username;
@property (nonatomic) UIImage * image;
@property (nonatomic) UIImage * highResImage;
@property (nonatomic) UIImage * stixLayer;
@property (nonatomic) UIImage * thumbnail;

@property (nonatomic) NSString * imageURL;
@property (nonatomic) NSString * stixLayerURL;
@property (nonatomic) NSString * highResImageURL;
@property (nonatomic) NSString * thumbnailURL;

-(void)encodeWithCoder:(NSCoder *)aCoder;
-(id)initWithCoder:(NSCoder *)aDecoder;
//-(id)initWithTag:(Tag *)tag;

/*
+(void)getTagAfterTimestamp:(NSDate*)timestamp totalTags:(int)count withCompletion:(PFArrayResultBlock)queryCompletedWithResults;
+(void)getTagBeforeTimestamp:(NSDate*)timestamp totalTags:(int)count withCompletion:(PFArrayResultBlock)queryCompletedWithResults;
-(Tag*)toTag;
*/
-(void)uploadWithBlock:(void (^)(NSString* newObjectID, BOOL didUploadImage))uploadDidComplete;

-(NSString*)getImageURL;
-(NSString*)getHiResImageURL;
-(NSString*)getStixLayerURL;
-(NSString*)getThumbnailURL;

-(void)addRelation:(NSString*)relation withUser:(PFUser *)user withBlock:(void (^)(BOOL succeeded, NSError *))addRelationResults;
@end
