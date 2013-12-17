//
//  AWSHelper.h
//  Stixx
//
//  Created by Bobby Ren on 11/16/12.
//
//

#import <Foundation/Foundation.h>

#import <AWSiOSSDK/S3/AmazonS3Client.h>
#import <AWSiOSSDK/SimpleDB/AmazonSimpleDBClient.h>
#import <AWSiOSSDK/SQS/AmazonSQSClient.h>
#import <AWSiOSSDK/SNS/AmazonSNSClient.h>
#import "AsyncImageUploader.h"

//#import "S3ResponseHandler.h"
//#import <AWSiOSSDK/S3/S3Request.h>

#define AWS_ACCESS_KEY @"AKIAITYWBOUSFNOLYMKQ"
#define AWS_SECRET_KEY @"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"
#define IMAGE_URL_BUCKET @"stix.parse.tags"
#define HIRES_IMAGE_URL_BUCKET @"stix.parse.tags.highres"
#define STIXLAYER_IMAGE_URL_BUCKET @"stix.parse.tags.stixlayer"
#define THUMBNAIL_IMAGE_URL_BUCKET @"stix.parse.tags.thumbnail"


@interface AWSHelper : NSObject <AmazonServiceRequestDelegate>

+(AmazonS3Client *)s3;
+(AmazonSimpleDBClient *)sdb;
+(AmazonSQSClient *)sqs;
+(AmazonSNSClient *)sns;

+(bool)hasCredentials;
+(void)validateCredentials;
+(void)clearCredentials;
+(void)uploadImage:(UIImage*)image withName:(NSString*)imageName toBucket:(NSString*)bucket withCallback:(void (^)(NSString *))block;
+(NSString*)getURLForKey:(NSString*)imageName inBucket:(NSString*)bucket;
+(void)putObject;
+(void)getObject;
@end
