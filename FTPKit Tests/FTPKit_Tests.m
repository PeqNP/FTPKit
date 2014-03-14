//
//  FTPKit_Tests.m
//  FTPKit Tests
//
//  Created by Eric Chamberlain on 3/7/14.
//  Copyright (c) 2014 Upstart Illustration LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FTPKit.h"

@interface FTPKit_Tests : XCTestCase <FTPClientDelegate>
@property (nonatomic, copy) void (^testBlock)(FTPClient *client, FTPRequest *request, BOOL failed);
@end

@implementation FTPKit_Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testNSError
{
    
}

- (void)testNSURL
{
    
}

- (void)testFtp
{
    FTPClient * ftp = [[FTPClient alloc] initWithHost:@"localhost" port:21 username:@"unittest" password:@"unitpass"];
    
    /* For now I am using the FTPKitSample project to test FTP functions. This
       will be changed once I am able to setup an asynchronous testing
       framework. */
    
    // Create 'test1.txt' file to upload. Contents are 'testing 1'.
    // Upload file 'test1.txt'.
    // Create 'test1' folder.
    // Create file 'test2.xt' in 'test1' folder. Contents are 'testing 2'.
    // Download 'test1.txt'. Ensure contents are 'testing 1'.
    // Download 'test2.txt'. Ensure contents are 'testing 2'.
    // List folder 'test1'. Should contain 'test[1|2].txt'
    // chmod permissions to 0777 on file 'test1.txt'
    // Delete folder 'test1' - it should fail as files still exist in the folder.
    // Delete 'test1.txt'
    // Delete 'test2.txt'
    // Delete folder 'test1'
    
    // Test listing directory contents where there is no whack on the end of
    // the path.
    
    // Move file 'test1.txt' into 'test1' folder.
    // Change
    
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

- (void)client:(FTPClient *)client request:(FTPRequest *)request didMakeDirectory:(NSURL *)directoryURL
{
    
}

- (void)client:(FTPClient *)client request:(FTPRequest *)request didUploadFile:(NSString *)sourcePath toDestination:(NSURL *)destinationURL
{
    
}

- (void)client:(FTPClient *)client request:(FTPRequest *)request didListItems:(NSArray *)items
{
    
}

- (void)client:(FTPClient *)client request:(FTPRequest *)request didChmodFile:(NSURL *)fileURL toMode:(int)mode
{
    
}

- (void)client:(FTPClient *)client request:(FTPRequest *)request didDownloadFile:(NSURL *)sourceURL toDestination:(NSString *)destinationPath
{
    
}

- (void)client:(FTPClient *)client request:(FTPRequest *)request didDeleteFile:(NSURL *)fileURL
{
    
}

- (void)client:(FTPClient *)client request:(FTPRequest *)request didFailWithError:(NSError *)error
{
    
}

@end
