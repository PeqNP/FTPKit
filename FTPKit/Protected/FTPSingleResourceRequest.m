//
//  FTPSingleResourceRequest.m
//  FTPKit
//
//  Created by Eric Chamberlain on 3/7/14.
//  Copyright (c) 2014 Upstart Illustration LLC. All rights reserved.
//

#import "FTPSingleResourceRequest.h"

@interface FTPSingleResourceRequest()
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) FTPHandle *handle;
@end

@implementation FTPSingleResourceRequest

@synthesize path;

+ (instancetype)requestWithCredentials:(FTPCredentials *)credentials path:(NSString *)path
{
    return [[self alloc] initWithCredentials:credentials path:path];
}

+ (instancetype)requestWithCredentials:(FTPCredentials *)credentials handle:(FTPHandle *)handle
{
    // @todo
    return nil;
}

- (instancetype)initWithCredentials:(FTPCredentials *)aCredentials path:(NSString *)aPath
{
    self = [super initWithCredentials:aCredentials];
    if (self)
    {
        self.path = aPath;
    }
    return self;
}

@end
