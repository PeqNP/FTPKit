//
//  TestCase.h
//  FTPKitSample
//
//  Created by Eric Chamberlain on 3/10/14.
//  Copyright (c) 2014 Upstart Illustration LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FTPKit/FTPKit.h>

@class TestCase;

@protocol TestCaseDelegate <NSObject>
- (void)testCaseDidFinish:(TestCase *)testCase;
@end

@interface TestCase : NSObject
{
    FTPClient *ftp;
}

@property (nonatomic, weak) id<TestCaseDelegate> delegate;
@property (nonatomic, strong) FTPClient *ftp;

- (void)connect;
- (void)run;

@end
