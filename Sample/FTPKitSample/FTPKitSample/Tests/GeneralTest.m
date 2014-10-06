
#import "GeneralTest.h"

@implementation GeneralTest

- (void)run
{
    // TODO:
    // Make sure hidden files are returned.
    // Make sure you can not rename a file to a dest file that already exists.
    
    self.ftp = [FTPClient clientWithHost:@"localhost" port:21 username:@"unittest" password:@"unitpass"];
    NSURL *localUrl = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"ftplib.tgz"];
    
    [ftp directoryExistsAtPath:@"/" success:^(BOOL exists) {
        if (exists) {
            NSLog(@"Success: 000");
        } else {
            NSLog(@"Error: Root path '/' must exist");
        }
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    // Note: All of these actions will queue in the order they are called.
    // Note: All of these tests are 1 to 1 relationship with the tests used within
    // the FTPKit, except the actions are synchronized.
    [ftp listContentsAtPath:@"/test" showHiddenFiles:YES success:^(NSArray *contents) {
        if (contents.count == 0) {
            NSLog(@"Success 001");
        } else {
            NSLog(@"Error: Should not have no contents!");
        }
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    /*
     * @todo
     *
    long long int bytes = [ftp fileSizeAtPath:@"/ftplib.tgz"];
    XCTAssertTrue((bytes > 0), @"");
    
    bytes = [ftp fileSizeAtPath:@"/copy.tgz"];
    XCTAssertEqual(-1, -1, @"");
     */
    
    [ftp downloadFile:@"/ftplib.tgz" to:localUrl.path progress:NULL success:^(void) {
        NSLog(@"Success 002");
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [ftp uploadFile:localUrl.path to:@"/copy.tgz" progress:NULL success:^(void) {
        NSLog(@"Success 003");
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [ftp chmodPath:@"/copy.tgz" toMode:777 success:^(void) {
        NSLog(@"Success 004");
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [ftp createDirectoryAtPath:@"/test" success:^(void) {
        NSLog(@"Success 005");
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    // chmod 'test' to 777
    [ftp chmodPath:@"/test" toMode:777 success:^(void) {
        NSLog(@"Success 006");
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [ftp listContentsAtPath:@"/test" showHiddenFiles:YES success:^(NSArray *contents) {
        if (contents.count == 0) {
            NSLog(@"Success 007");
        } else {
            NSLog(@"Error: Should not have no contents!");
        }
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [ftp renamePath:@"/copy.tgz" to:@"/test/copy.tgz" success:^(void) {
        NSLog(@"Success 008");
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [ftp createDirectoryAtPath:@"/test/test2" success:^(void) {
        NSLog(@"Success 009");
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [ftp listContentsAtPath:@"/test" showHiddenFiles:YES success:^(NSArray *contents) {
        if (contents.count == 2) {
            NSLog(@"Success 010");
        } else {
            NSLog(@"Error: Must have contents!");
        }
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [ftp deleteDirectoryAtPath:@"/test" success:^(void) {
        NSLog(@"Error: Should have failed!");
    } failure:^(NSError *error) {
        NSLog(@"Success 011 -- Error: %@", error.localizedDescription);
    }];
    
    [ftp deleteFileAtPath:@"/test/copy.tgz" success:^(void) {
        NSLog(@"Success 012");
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];

    [ftp deleteDirectoryAtPath:@"/test/test2" success:^(void) {
        NSLog(@"Success 013");
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    // Add a file that has a space in the name.
    [ftp uploadFile:localUrl.path to:@"/test/Hello World.tgz" progress:NULL success:^(void) {
        NSLog(@"Success 013-a");
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [ftp chmodPath:@"/test/Hello World.tgz" toMode:777 success:^(void) {
        NSLog(@"Success 013-b");
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [ftp renamePath:@"/test/Hello World.tgz" to:@"/test/eric test.tgz" success:^(void) {
        NSLog(@"Success 013-c");
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [ftp lastModifiedAtPath:@"/test/eric test.tgz" success:^(NSDate *lastModified) {
        NSLog(@"Success 013-d -- Date: %@", lastModified);
        long long filesize = [ftp fileSizeAtPath:@"/test/eric test.tgz"];
        if (filesize > 0) {
            NSLog(@"Success 013-e -- Size: %llu", filesize);
        } else {
            NSLog(@"Error: filesizeAtPath: failed.");
        }
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [ftp listContentsAtPath:@"/test" showHiddenFiles:NO success:^(NSArray *contents) {
        if (contents.count == 1) {
            NSLog(@"Success 013-f -- Contents (%@)", ((FTPHandle *)[contents objectAtIndex:0]).name);
        } else {
            NSLog(@"Error: Too many folders (%@)", [contents componentsJoinedByString:@", "]);
        }
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [ftp deleteFileAtPath:@"/test/eric test.tgz" success:^(void) {
        NSLog(@"Success 013-g");
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [ftp createDirectoryAtPath:@"/test/Hello World" success:^(void) {
        NSLog(@"Success 013-h");
        if ([ftp changeDirectoryToPath:@"/test/Hello World"]) {
            NSLog(@"Success 013-i");
        } else {
            NSLog(@"Error: Failed to change directory w/ space in name");
        }
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [ftp directoryExistsAtPath:@"/test/Hello World" success:^(BOOL exists) {
        if (exists) {
            NSLog(@"Success 013-j");
        } else {
            NSLog(@"Error: Failed to determine if directory exists w/ space in name");
        }
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    // @todo Add contents to this folder before testing.
    [ftp listContentsAtPath:@"/test/Hello World" showHiddenFiles:NO success:^(NSArray *contents) {
        NSLog(@"Success 013-k -- Contents.count (%lu)", contents.count);
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [ftp deleteDirectoryAtPath:@"/test/Hello World" success:^(void) {
        NSLog(@"Success 013-l");
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    // @todo one more.. can't remember.
    
    [ftp deleteDirectoryAtPath:@"/test" success:^(void) {
        NSLog(@"Success 014");
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [ftp directoryExistsAtPath:@"/badpath" success:^(BOOL exists) {
        if (exists) {
            NSLog(@"Error: /badpath should not exist");
        } else {
            NSLog(@"Success 015");
        }
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [ftp lastModifiedAtPath:@"/ftplib.tgz" success:^(NSDate *lastModified) {
        NSLog(@"Success 016 -- Date: %@", lastModified);
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }];
}

@end
