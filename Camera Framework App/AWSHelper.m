//
//  AWSHelper.m
//  Stixx
//
//  Created by Bobby Ren on 11/16/12.
//
//

#import "AWSHelper.h"

static AmazonS3Client       *s3  = nil;
static AmazonSimpleDBClient *sdb = nil;
static AmazonSQSClient      *sqs = nil;
static AmazonSNSClient      *sns = nil;
/*
static S3PutObjectRequest *putObjectRequest = nil;
static S3GetObjectRequest *getObjectRequest = nil;
static S3ResponseHandler * s3ResponseHandler = nil;
*/
@implementation AWSHelper

+(AmazonS3Client *)s3
{
    [AWSHelper validateCredentials];
    return s3;
}

+(AmazonSimpleDBClient *)sdb
{
    [AWSHelper validateCredentials];
    return sdb;
}

+(AmazonSQSClient *)sqs
{
    [AWSHelper validateCredentials];
    return sqs;
}

+(AmazonSNSClient *)sns
{
    [AWSHelper validateCredentials];
    return sns;
}
/*
+(S3ResponseHandler *) s3ResponseHandler {
    if (!s3ResponseHandler)
        s3ResponseHandler = [[S3ResponseHandler alloc] init];
    return s3ResponseHandler;
}
+(S3PutObjectRequest *) putObjectRequest {
    if (!putObjectRequest)
        putObjectRequest = [[S3PutObjectRequest alloc] init];
    return putObjectRequest;
}

+(S3GetObjectRequest *) getObjectRequest {
    if (!getObjectRequest)
        getObjectRequest = [[S3GetObjectRequest alloc] init];
    return getObjectRequest;
}
*/

+(bool)hasCredentials
{
    return YES;
//    return (![AWS_ACCESS_KEY isEqualToString:@"CHANGE ME"] && ![AWS_SECRET_KEY isEqualToString:@"CHANGE ME"]);
}

+(void)validateCredentials
{
    if ((sdb == nil) || (s3 == nil) || (sqs == nil) || (sns == nil)) {
        [AWSHelper clearCredentials];
        
        s3  = [[AmazonS3Client alloc] initWithAccessKey:AWS_ACCESS_KEY withSecretKey:AWS_SECRET_KEY];
        sdb = [[AmazonSimpleDBClient alloc] initWithAccessKey:AWS_ACCESS_KEY withSecretKey:AWS_SECRET_KEY];
        sqs = [[AmazonSQSClient alloc] initWithAccessKey:AWS_ACCESS_KEY withSecretKey:AWS_SECRET_KEY];
        sns = [[AmazonSNSClient alloc] initWithAccessKey:AWS_ACCESS_KEY withSecretKey:AWS_SECRET_KEY];
    }
}

+(void)clearCredentials
{
    s3  = nil;
    sdb = nil;
    sqs = nil;
    sns = nil;
}

+(void)uploadImage:(UIImage*)image withName:(NSString*)imageName toBucket:(NSString*)bucket withCallback:(void (^)(NSString *))block{
    AsyncImageUploader * uploader = [[AsyncImageUploader alloc] init];
    [uploader uploadImage:image name:imageName withBucket:(NSString*)bucket withCallback:^(BOOL success, id response) {
        NSLog(@"Success: %d", success);
        if (success) {
            NSLog(@"Response: %@", response);
            NSString * url = [self getURLForKey:imageName inBucket:bucket];
            NSLog(@"URL: %@", url);
        }
        else {
            NSError * error = (NSError*) response;
            NSLog(@"Error: %@", error);
            // todo: handle typical error:
            // Error: AmazonServiceException { RequestId:B13EC740D9C486DA, ErrorCode:RequestTimeout, Message:Your socket connection to the server was not read from or written to within the timeout period. Idle connections will be closed. }
        }
    }];
}

+(NSString*)getURLForKey:(NSString*)imageName inBucket:(NSString*)bucket {
    // get image url
    S3ResponseHeaderOverrides *override = [[S3ResponseHeaderOverrides alloc] init];
    override.contentType = @"image/png";
    
    S3GetPreSignedURLRequest *gpsur = [[S3GetPreSignedURLRequest alloc] init];
    gpsur.key     = imageName;
    gpsur.bucket  = bucket;
    gpsur.expires = [NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval) 3600];  // Added an hour's worth of seconds to the current time.
    gpsur.responseHeaderOverrides = override;
    
    NSURL *url = [self.s3 getPreSignedURL:gpsur];
    //NSLog(@"url for key %@: %@", imageName, url);
    NSString * urlString = [NSString stringWithFormat:@"%@", url];
    return urlString;
}
@end
