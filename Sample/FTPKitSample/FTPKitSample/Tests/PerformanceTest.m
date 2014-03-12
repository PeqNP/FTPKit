//
//  PerformanceTest.m
//  FTPKitSample
//
//  Created by Eric Chamberlain on 3/11/14.
//  Copyright (c) 2014 Upstart Illustration LLC. All rights reserved.
//

#import "PerformanceTest.h"

#define NUM_TESTS 1000

@interface PerformanceTest()
@property (nonatomic, assign) NSInteger counter;
@property (nonatomic, strong) NSString *localPath;
@end

@implementation PerformanceTest

- (void)run
{
    // Test: Uploading a file 1000x
    // Test: Downloading a file 1000x
    _counter = 0;
    
    [self connect];
    NSURL *localUrl = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"ftplib.tgz"];
    self.localPath = localUrl.path;
    [ftp downloadFile:@"/ftplib.tgz" to:localUrl.path];
}

- (void)client:(FTPClient *)client request:(FTPRequest *)request didDownloadFile:(NSString *)remotePath to:(NSString *)localPath
{
    _counter++;
    if (_counter == NUM_TESTS)
    {
        _counter = 0;
        [self.delegate testCaseDidFinish:self];
        return;
        [ftp uploadFile:localPath to:@"/copy.tgz"];
    }
    else
    {
        [ftp downloadFile:remotePath to:localPath];
    }
}

- (void)client:(FTPClient *)client request:(FTPRequest *)request didUploadFile:(NSString *)localPath to:(NSString *)remotePath
{
    _counter++;
    if (_counter == NUM_TESTS)
    {
        [self.delegate testCaseDidFinish:self];
    }
    else
    {
        // Delete and then re-upload the file.
        //[ftp uploadFile:localPath to:remotePath];
        [ftp deleteFileAtPath:remotePath];
    }
}

- (void)client:(FTPClient *)client request:(FTPRequest *)request didDeletePath:(NSString *)path
{
    [ftp uploadFile:_localPath to:@"/copy.tgz"];
}

@end
