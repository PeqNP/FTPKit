
#import "GeneralTest.h"

@implementation GeneralTest

- (void)run
{
    self.ftp = [FTPClient clientWithHost:@"localhost" port:21 username:@"unittest" password:@"unitpass"];
    ftp.delegate = self;
    NSURL *localUrl = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"ftplib.tgz"];
    [ftp downloadFile:@"/ftplib.tgz" to:localUrl.path];
}


- (void)client:(FTPClient *)client request:(FTPRequest *)request didDownloadFile:(NSString *)remotePath to:(NSString *)localPath
{
    [client uploadFile:localPath to:@"/copy.tgz"];
}

- (void)client:(FTPClient *)client request:(FTPRequest *)request didUploadFile:(NSString *)localPath to:(NSString *)remotePath
{
    [client chmodPath:remotePath toMode:777];
}

- (void)client:(FTPClient *)client request:(FTPRequest *)request didChmodPath:(NSString *)path toMode:(int)mode
{
    if ([path isEqualToString:@"/copy.tgz"])
    {
        // test chmod'ing folder
        [client createDirectoryAtPath:@"/test"];
    }
    else if ([path isEqualToString:@"/test"])
    {
        [client listContentsAtPath:@"/" showHiddenFiles:YES];
    }
    else
    {
        NSLog(@"ERROR");
    }
}

- (void)client:(FTPClient *)client request:(FTPRequest *)request didCreateDirectory:(NSString *)path
{
    [client chmodPath:path toMode:777];
}

- (void)client:(FTPClient *)client request:(FTPRequest *)request didListContents:(NSArray *)contents
{
    for (FTPHandle *handle in contents)
    {
        NSLog(@"handle: %@", handle.name);
    }
    [client renamePath:@"/copy.tgz" to:@"/test/copy.tgz"];
}

- (void)client:(FTPClient *)client request:(FTPRequest *)request didRenamePath:(NSString *)sourcePath to:(NSString *)destPath
{
    if ([sourcePath isEqualToString:@"/copy.tgz"])
    {
        [client renamePath:destPath to:@"/test/copy2.tgz"];
    }
    else if ([sourcePath isEqualToString:@"/test/copy.tgz"])
    {
        [client deleteFileAtPath:@"/test/copy2.tgz"];
    }
}

- (void)client:(FTPClient *)client request:(FTPRequest *)request didDeletePath:(NSString *)path
{
    if ([path isEqualToString:@"/test/copy2.tgz"])
    {
        [client deleteDirectoryAtPath:@"/test"];
    }
    else if ([path isEqualToString:@"/test"])
    {
        [self.delegate testCaseDidFinish:self];
    }
}

@end
