# FTPKit

Version 1.0.0b

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
    [client listContentsAtPath:@"/" showHiddenFiles:NO];

    ...

    // Delegate callback will return a list of FTPHandle objects.
    - (void)client:(FTPClient *)client request:(FTPRequest *)request didListContents:(NSArray *)handles
    {
        // Iterate through handles. Display them in a table, etc.
        for (FTPHandle *handle in handles)
        {
            if (handle.type == FTPHandleTypeFile)
            {
                // Do something with file.
            }
            else if (handle.type == FTPHandleTypeDirectory)
            {
                // Do something with directory.
            }
        }
    }

## Create a new directory

Continuing on from our previous example; below shows how to create a remote directory.

    [client createDirectoryAtPath:@"/my_new_folder"];

    ...

    // Delegate callback will inform you when the request is complete.
    - (void)client:(FTPClient *)client request:(FTPRequest *)request didCreateDirectory:(NSString *)path
    {
        // Add file to the list of files you are tracking?
    }

## Download a file

    [client downloadFile:@"index.html" to:@"/Users/me/index.html"];

    - (void)client:(FTPClient *)client request:(FTPRequest *)request didDownloadFile:(NSString *)remotePath to:(NSString *)localPath
    {
        // Open the file?
    }

## Upload a file
    
    // Upload index.html to the /public/ directory on the FTP server.
    [client uploadFile:@"index.html" to:@"/public/"];

    // Delegate callback.
    - (void)client:(FTPClient *)client request:(FTPRequest *)request didUploadFile:(NSString *)localPath to:(NSString *)remotePath
    {
        // ...
    }

## Rename a file
    
    // You can easily rename (or move) a file from one path to another.
    [client renamePath:@"/index.html" to:@"/public/index.html"];

    // Delegate callback.
    - (void)client:(FTPClient *)client request:(FTPRequest *)request didRenamePath:(NSString *)sourcePath to:(NSString *)destPath
    {
        // ...
    }

## Delete a file

    // You can either provide a FTPHandle or a path on the FTP server to delete.
    // The FTPHandle will have been returned from the listDirectory* method.
    [client deleteFileAtPath:@"/path/deleteme.html"];

    ...

    [client deleteDirectoryAtPath:@"/my_folder"];

    // Delegate callback.
    - (void)client:(FTPClient *)client request:(FTPRequest *)request didDeletePath:(NSString *)path
    {
        // ...
    }

## Cancel a request

Currently there are no requests that can be cancelled. This will change once the
underlying lib has been updated. However, the API for this has been complete.

    // Keep the request object around until we no longer need it.
    FTPRequest *request = [client downloadFile:@"my_remote_movie.mp4" to:@"/my/local/my_movie.mp4"];

    ...

    // Cancel the request.
    [request cancel];

    // Delegate callback will inform you that the process was cancelled.
    - (void)client:(FTPClient *)client requestDidCancel:(FTPRequest *)request
    {
        // Alert the user that the request cancelled? Or may they already know!
    }

## Update status of requests

As requests process, they will periodically notify the delegate of their status. Implement the following delegate callbacks to inform your end-user of the status.

    - (void)client:(FTPClient *)client request:(FTPRequest *)request didUpdateProgress:(float)progress
    {
        // This callback is useful for file uploads/downloads. Update your
        // UIProgressView, etc. here
    }

    - (void)client:(FTPClient *)client request:(FTPRequest *)request didUpdateStatus:(NSString *)status
    {
        // This will display the commands executed and general status updates --
        // such as when a connection is opened, complete, etc.
    }

## Error handling

When requests fail they will notify the delegate with the following call:

    - (void)client:(FTPClient *)client request:(FTPRequest *)request didFailWithError:(NSError *)error
    {
        // Display alert to end-user?
    }

# Setup & Integration

## Requirements

This project was developed using Xcode 5.0. It requires a deployment target of iOS 7 or greater or OS X 10.9. It will work with ARC projects. I'm not sure about non-ARC projects.

## Required Frameworks

- CFNetwork
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
