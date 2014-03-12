
#import "ftplib.h"

#import "FTPMakeDirectoryRequest.h"
#import "NSError+Additions.h"

@implementation FTPMakeDirectoryRequest

- (void)start
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queue, ^{
        [self didUpdateStatus:[NSString stringWithFormat:@"MKD %@", self.handle.path]];
        netbuf *conn = [self connect];
        if (conn == NULL)
            return;
        const char *path = [self.handle.path cStringUsingEncoding:NSUTF8StringEncoding];
        int stat = FtpMkdir(path, conn);
        FtpQuit(conn);
        if (stat == 0)
        {
            [self didFailWithError:[NSError FTPKitErrorWithCode:550]];
            return;
        }
        [self didUpdateStatus:NSLocalizedString(@"MKD Done", @"")];
        if ([self.delegate respondsToSelector:@selector(request:didMakeDirectory:)])
        {
            [self.delegate request:self didMakeDirectory:self.handle.path];
        }
    });
}

@end
