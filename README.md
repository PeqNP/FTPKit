# FTPKit

FTPKit is an Objective-C library providing facilities implementing the client
side of the File Transfer Protocol (FTP).

This lib is based off or inspired by the BlackRaccoon, WhiteReaccoon and Apple's SimpleFTP
example. It utilizes the FTPlib C library, developed by Chistophe Deleuze,
for some of the remote functions such as chmod and sending arbitrary commands.

## Features

- List directory contents
- Create new remote files and folders
- Delete remote files and folders
- Upload files
- Download files
- Change file mode on files (chmod)
- All calls are asynchronous
- Library is fully unit tested
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

Continuing on from our previous example, below shows you how you can create a remote directory.

    [client createDirectory:@"my_folder" atPath:@"/"];

    ...

    // Delegate callback will inform you when the request is complete.
    - (void)client:(FTPClient *)client request:(FTPRequest *)request didMakeDirectory:(NSString *)path
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

## Delete a file

    // You can either provide a FTPHandle or a path on the FTP server to delete.
    // The FTPHandle will have been returned from the listDirectory* method.
    [client deleteFile:@"/path/deleteme.html"];

    // Delegate callback.
    - (void)client:(FTPClient *)client request:(FTPRequest *)request didDeleteFile:(NSString *)path
    {
        // ...
    }

## Cancel a request

Most requests can be cancelled. In the instance where you need to cancel the
request, do the following:

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

As requests process, they will periodically notify the delegate of their
status. Implement the following delegate callbacks to inform your end-user
of the status.

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

When request fail they will notify the delegate with the following call:

    - (void)client:(FTPClient *)client request:(FTPRequest *)request didFailWithError:(NSError *)error
    {
        // Display alert to end-user?
    }

# Setup & Integration

## Requirements

This project was developed using Xcode 5.0. It requires a deployment target of iOS 7 or greater or OS X 10.9. It will work with ARC projects. I'm not sure about non-ARC projects.

## Required Frameworks

- Foundation
- CFNetwork

If you add FTPKit to your project as a static library, you will need to set the **-ObjC** and **-all_load** linker flags. Look below for more details.

## Integration

1. Drag the "FTPKit.xcodeproj" into your project.
2. Add the required library and frameworks (refer screenshot below).
    - Open the "Build Phases" tab
    - Expand Link Binary With Libraries
    - Click the "+" button and add CFNetwork.framework, Foundation.framework and libFTPKit.a
3. Add linker flags.
    - Open the "Build Settings" tab
	- Find "Other Linker Flags" and set the value to **-ObjC -all_load**
4. Add the FTPKit header file, **#import <FTPKit/FTPKit.h>**, where you want to use the library.

![][1]


  [1]: https://dl.dropboxusercontent.com/u/55773661/FTPKit/xcode.png
