
#import "ftplib.h"

#import "FTPMakeDirectoryRequest.h"
#import "NSError+Additions.h"

@implementation FTPMakeDirectoryRequest

- (BOOL)start
{
    [self didUpdateStatus:[NSString stringWithFormat:@"MKD %@", self.handle.path]];
    netbuf *conn = [self connect];
    if (conn == NULL)
    {
        [self didFailWithError:[NSError FTPKitErrorWithCode:10060]];
        return NO;
    }
    const char *path = [self.handle.path cStringUsingEncoding:NSUTF8StringEncoding];
    int stat = FtpMkdir(path, conn);
    FtpQuit(conn);
    if (stat == 0)
    {
        [self didFailWithError:[NSError FTPKitErrorWithCode:550]];
        return NO;
    }
    [self didUpdateStatus:NSLocalizedString(@"MKD Done", @"")];
    return YES;
}

@end
