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

- (void)run
{
    // Nothing to do.
}

- (void)client:(FTPClient *)client request:(FTPRequest *)request didUpdateStatus:(NSString *)status
{
    // @todo
}

- (void)client:(FTPClient *)client request:(FTPRequest *)request didFailWithError:(NSError *)error
{
    // @todo
}

@end
