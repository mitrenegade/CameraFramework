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
#import "Constants.h"

@interface ParseTag : NSObject <PFObjectFactory>

@property (nonatomic) PFObject * pfObject;
@property (nonatomic) NSString * username;
@property (nonatomic) UIImage * image;
@property (nonatomic) UIImage * highResImage;
@property (nonatomic) UIImage * stixLayer;
@property (nonatomic) UIImage * thumbnail;

@property (nonatomic) NSString * imageURL;
@property (nonatomic) NSString * stixLayerURL;
@property (nonatomic) NSString * highResImageURL;
@property (nonatomic) NSString * thumbnailURL;

-(NSString*)getImageURL;
-(NSString*)getHiResImageURL;
-(NSString*)getStixLayerURL;
-(NSString*)getThumbnailURL;

-(void)addRelation:(NSString*)relation withUser:(PFUser *)user withBlock:(void (^)(BOOL succeeded, NSError *))addRelationResults;
@end
