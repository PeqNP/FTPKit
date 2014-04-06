//
//  PerformanceTest.m
//  FTPKitSample
//
//  Created by Eric Chamberlain on 3/11/14.
//  Copyright (c) 2014 Upstart Illustration LLC. All rights reserved.
//

#import "PerformanceTest.h"

#define NUM_TESTS 50

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
}

@end
