# FTPKit

Version 1.3.1

FTPKit is an Objective-C library providing facilities implementing the client
side of the File Transfer Protocol (FTP).

This lib is based off or inspired by the BlackRaccoon, WhiteReaccoon and Apple's SimpleFTP
example. It utilizes the ftplib library, developed by Thomas Pfau, for most of
the remote actions.

## Features

- List directory contents
- Upload files
- Download files
- Delete remote files and folders
- Change file mode on files (chmod)
- Rename (move) files from one path to another
- All calls are asynchronous
- Built with ARC

# Tutorial

## List directory contents

    #import <FTPKit/FTPKit.h>

    ...

    // Connect and list contents.
    FTPClient *client = [FTPClient clientWithHost:@"localhost" port:21 username:@"user" password:@"pass"];
    NSArray *contents = [client listContentsAtPath:@"/" showHiddenFiles:NO];

    if (contents /* Returns nil if an error occured */) {
        // Iterate through handles. Display them in a table, etc.
        for (FTPHandle *handle in handles) {
            if (handle.type == FTPHandleTypeFile) {
                // Do something with file.
            } else if (handle.type == FTPHandleTypeDirectory) {
                // Do something with directory.
            }
        }
    } else {
        // Display error using: client.lastError
    }

    ...

    // Or, make the call asynchronous;
    [client listContentsAtPath:@"/test" showHiddenFiles:YES success:^(NSArray *contents) {
        if (handle.type == FTPHandleTypeFile) {
            // Do something with file.
        } else if (handle.type == FTPHandleTypeDirectory) {
            // Do something with directory.
        }
    } failure:^(NSError *error) {
        // Display error...
    }];



## Create a new directory

Continuing on from our previous example; below shows how to create a remote directory.

    BOOL success = [client createDirectoryAtPath:@"/my_new_folder"];
    if (! success) {
        // Display error...
    }

    ...

    // Or, make the call asynchronous;
    [client createDirectoryAtPath:@"/my_new_folder" success:^(void) {
        // Success!
    } failure:^(NSError *error) {
        // Display an error...
    }];

## Download a file

    BOOL success = [client downloadFile:@"/index.html" to:@"/Users/me/index.html"];
    if (! success) {
        // Display an error...
    }
    
    ...

    // Or, make the call asynchronous;
    [client downloadFile:@"/index.html" to:@"/Users/me/index.html" progress:NULL success:^(void) {
        // Success!
    } failure:^(NSError *error) {
        // Display an error...
    }];

Please note that the `progress:` parameter has not yet been implemented.

## Upload a file
    
    // Upload index.html to the /public/ directory on the FTP server.
    BOOL success = [client uploadFile:@"index.html" to:@"/public/index.html"];
    if (! success) {
        // Display an error...
    }

    ...

    // Or, make the call asynchronous;
    [client uploadFile:@"index.html" to:@"/public/index.html" progress:NULL success:^(void) {
        // Success!
    } failure:^(NSError *error) {
        // Display an error...
    }];

## Rename a file
    
    // You can easily rename (or move) a file from one path to another.
    BOOL success = [client renamePath:@"/index.html" to:@"/public/index.html"];
    if (! success) {
        // Display an error...
    }

    ...

    // Or, make the call asynchronous;
    [client renamePath:@"/index.html" to:@"/public/index.html" success:^(void) {
        // Success!
    } failure:^(NSError *error) {
        // Display an error...
    }];

## Delete a file

    // You can either provide a FTPHandle or a path on the FTP server to delete.
    // The FTPHandle will have been returned from the listDirectory* method.
    BOOL success = [client deleteFileAtPath:@"/path/deleteme.html"];
    if (! success) {
        // Display an error...
    }

    ...

    // Or, make the call asynchronous;
    [client deleteFileAtPath:@"/path/deleteme.html" success:^(void) {
        // Success!
    } failure:^(NSError *error) {
        // Display an error...
    }];

## chmod a file

    BOOL success = [client chmodPath:@"/public/defaceme.html" toMode:777];
    if (! success) {
        // Display an error...
    }

    ...

    // Or, make the call asynchronous;
    [client chmodPath:@"/public/defaceme.html" toMode:777 success:^(void) {
        // Success!
    } failure:^(NSError *error) {
        // Display an error...
    }];

## Check if a directory exists

    BOOL success = [ftp directoryExistsAtPath:@"/mypath"];
    if (! success) {
        // Display an error...
    }

    ...

    // Or, make the call asynchronous;
    [ftp directoryExistsAtPath:@"/mypath" success:^(BOOL exists) {
        if (exists) {
            // The file exists.
        } else {
            // The file doesn't exist.
        }
    } failure:^(NSError *error) {
        // Display an error...
    }];

# Setup & Integration

## Requirements

This project was developed using Xcode 5.0. It requires a deployment target of iOS 7 or greater or OS X 10.9. It will work with ARC projects. I'm not sure about non-ARC projects.

## Required Frameworks

- Foundation

If you add FTPKit to your project as a static library, you will need to set the **-ObjC** and **-all_load** linker flags. Look below for more details.

## Integration

1. Drag the "FTPKit.xcodeproj" into your project.
2. Add the FTPKit (FTPKit) as a Target Dependency (refer to the screehnshot below)
3. Add the required library and frameworks (refer screenshot below).
    - Open the "Build Phases" tab
    - Expand Link Binary With Libraries
    - Click the "+" button and add CFNetwork.framework, Foundation.framework and libFTPKit.a
4. Add linker flags.
    - Open the "Build Settings" tab
    - Find "Other Linker Flags" and set the value to **-ObjC -all_load**
5. Add the FTPKit header file, **#import \<FTPKit/FTPKit.h\>**, where you want to use the library.

### Notes

The #import \<FTPKit/FTPKit.h\> header may not be recognized until you build the project. After the project builds for the first time the error will go away.

![][1]


  [1]: https://dl.dropboxusercontent.com/u/55773661/FTPKit/xcode.png
