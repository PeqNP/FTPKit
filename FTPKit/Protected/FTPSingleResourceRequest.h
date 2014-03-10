//
//  FTPSingleResourceRequest.h
//  FTPKit
//
//  Created by Eric Chamberlain on 3/7/14.
//  Copyright (c) 2014 Upstart Illustration LLC. All rights reserved.
//

#import "FTPRequest.h"
#import "FTPHandle.h"

@interface FTPSingleResourceRequest : FTPRequest

@property (nonatomic, readonly) FTPHandle *handle;

// @todo
+ (instancetype)requestWithCredentials:(FTPCredentials *)credentials handle:(FTPHandle *)handle;

- (instancetype)initWithCredentials:(FTPCredentials *)credentials handle:(FTPHandle *)handle;

@end
