//
//  HandleTests.m
//  FTPKitSample
//
//  Created by Eric Chamberlain on 3/11/14.
//  Copyright (c) 2014 Upstart Illustration LLC. All rights reserved.
//

#import "HandleTest.h"

@implementation HandleTest

- (void)run
{
    // @todo Make sure that files that contain spaces, or special characters,
    // are escaped as they should before being sent to the FTP server.
    // Test: Create /My File.txt (file)
    //       Create /My (file)
    //       Create /My File (directory)
    // Test: Delete file /My File.txt
    // This should not delete '/My'
    // Test: Delete folder with space
    
    [self connect];
    NSURL *localUrl = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"My File.tgz"];
}

@end
