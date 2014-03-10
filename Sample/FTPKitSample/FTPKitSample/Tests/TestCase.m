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
    NSLog(@"Status: %@", status);
}

- (void)client:(FTPClient *)client request:(FTPRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Failed (%@)", error);
}

@end
