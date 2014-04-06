//
//  TestCase.m
//  FTPKitSample
//
//  Created by Eric Chamberlain on 3/10/14.
//  Copyright (c) 2014 Upstart Illustration LLC. All rights reserved.
//

#import "TestCase.h"

@implementation TestCase

@synthesize ftp;

- (void)connect
{
    self.ftp = [FTPClient clientWithHost:@"localhost" port:21 username:@"unittest" password:@"unitpass"];
}

- (void)run
{
    // Nothing to do.
}

@end
