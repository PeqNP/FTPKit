#import "FTPKit.h"
#import "FTPDeleteFileRequest.h"
#import "NSError+Additions.h"
#import "FTPKit+Protected.h"

@implementation FTPDeleteFileRequest

- (void)start
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queue, ^{
        [self didUpdateStatus:[NSString stringWithFormat:@"DELE %@", self.handle.path]];
        netbuf *conn = [self connect];
        if (conn == NULL)
            return;
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
            return;
        }
        [self didUpdateStatus:NSLocalizedString(@"DELE Done", @"")];
        if ([self.delegate respondsToSelector:@selector(request:didDeletePath:)])
        {
            [self.delegate request:self didDeletePath:self.handle.path];
        }
    });
}

@end
