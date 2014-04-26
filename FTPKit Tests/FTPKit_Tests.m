//
//  FTPKit_Tests.m
//  FTPKit Tests
//
//  Created by Eric Chamberlain on 3/7/14.
//  Copyright (c) 2014 Upstart Illustration LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FTPKit.h"
#import "FTPKit+Protected.h"

@interface FTPKit_Tests : XCTestCase

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
    
    NSArray *contents = [ftp listContentsAtPath:@"/test" showHiddenFiles:YES];
    //XCTAssertNil(contents, @"Directory should not exist");
    XCTAssertEqual(0, contents.count, @"");
    
    long long int bytes = [ftp fileSizeAtPath:@"/ftplib.tgz"];
    XCTAssertTrue((bytes > 0), @"");
    
    bytes = [ftp fileSizeAtPath:@"/copy.tgz"];
    XCTAssertEqual(-1, -1, @"");
    
    // Create 'test1.txt' file to upload. Contents are 'testing 1'.
    NSURL *localUrl = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"ftplib.tgz"];
    
    // Download 'ftplib.tgz'
    BOOL success = [ftp downloadFile:@"/ftplib.tgz" to:localUrl.path progress:NULL];
    XCTAssertTrue(success, @"");
    
    // Upload 'ftplib.tgz' as 'copy.tgz'
    success = [ftp uploadFile:localUrl.path to:@"/copy.tgz" progress:NULL];
    XCTAssertTrue(success, @"");
    
    // chmod 'copy.tgz' to 777
    success = [ftp chmodPath:@"/copy.tgz" toMode:777];
    XCTAssertTrue(success, @"");
    
    // Create directory 'test'
    success = [ftp createDirectoryAtPath:@"/test"];
    XCTAssertTrue(success, @"");
    
    NSDate *date = [ftp lastModifiedAtPath:@"/ftplib.tgz"];
    NSLog(@"date %@", date);
    XCTAssertNotNil(date, @"");
    // @todo
    
    // chmod 'test' to 777
    success = [ftp chmodPath:@"/test" toMode:777];
    XCTAssertTrue(success, @"");
    
    // List contents of 'test'
    contents = [ftp listContentsAtPath:@"/test" showHiddenFiles:YES];
    
    // - Make sure there are no contents.
    XCTAssertEqual(0, contents.count, @"There should be no contents");
    
    // Move 'copy.tgz' to 'test' directory
    success = [ftp renamePath:@"/copy.tgz" to:@"/test/copy.tgz"];
    XCTAssertTrue(success, @"");
    
    // Copy 'copy.tgz' to 'copy2.tgz'
    success = [ftp copyPath:@"/test/copy.tgz" to:@"/test/copy2.tgz"];
    XCTAssertTrue(success, @"");
    
    // Create '/test/test2' directory
    success = [ftp createDirectoryAtPath:@"/test/test2"];
    XCTAssertTrue(success, @"");
    
    // List contents of 'test'
    contents = [ftp listContentsAtPath:@"/test" showHiddenFiles:YES];
    
    // - Should have 'copy.tgz' (a file) and 'test2' (a directory)
    // @todo make sure they are the files we requested, including the correct
    // file type.
    XCTAssertEqual(3, contents.count, @"");
    
    // Delete 'test'. It should fail as there are contents in the directory.
    success = [ftp deleteDirectoryAtPath:@"/test"];
    XCTAssertFalse(success, @"Directory has contents");
    
    // Delete 'test2', 'copy.tgz' and then 'test'. All operations should succeed.
    success = [ftp deleteFileAtPath:@"/test/copy.tgz"];
    XCTAssertTrue(success, @"");
    success = [ftp deleteFileAtPath:@"/test/copy2.tgz"];
    XCTAssertTrue(success, @"");
    success = [ftp deleteDirectoryAtPath:@"/test/test2"];
    XCTAssertTrue(success, @"");
    success = [ftp deleteDirectoryAtPath:@"/test"];
    XCTAssertTrue(success, @"");
    
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
