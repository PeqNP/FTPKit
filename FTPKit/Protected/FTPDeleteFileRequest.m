
#import "ftplib.h"

#import "FTPDeleteFileRequest.h"
#import "NSError+Additions.h"

@implementation FTPDeleteFileRequest

- (BOOL)start
{
    [self didUpdateStatus:[NSString stringWithFormat:@"DELE %@", self.handle.path]];
    netbuf *conn = [self connect];
    if (conn == NULL)
    {
        [self didFailWithError:[NSError FTPKitErrorWithCode:10060]];
        return NO;
    }
    const char *path = [self.handle.path cStringUsingEncoding:NSUTF8StringEncoding];
    int stat = 0;
    if (self.handle.type == FTPHandleTypeDirectory)
        stat = FtpRmdir(path, conn);
    else
        stat = FtpDelete(path, conn);
    FtpQuit(conn);
    if (stat == 0)
    {
        [self didFailWithError:[NSError FTPKitErrorWithCode:550]];
        return NO;
    }
    [self didUpdateStatus:NSLocalizedString(@"DELE Done", @"")];
    return YES;
}

@end
