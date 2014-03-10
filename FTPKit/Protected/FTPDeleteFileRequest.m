#import "FTPKit.h"
#import "FTPDeleteFileRequest.h"
#import "NSError+Additions.h"
#import "FTPKit+Protected.h"

#import <CFNetwork/CFNetwork.h>

@implementation FTPDeleteFileRequest

- (void)start
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queue, ^{
        const char *host = [self.credentials.host cStringUsingEncoding:NSUTF8StringEncoding];
        const char *login = [self.credentials.username cStringUsingEncoding:NSUTF8StringEncoding];
        const char *password = [self.credentials.password cStringUsingEncoding:NSUTF8StringEncoding];
        if (ftp_open(host, login, password))
        {
            [self didFailWithError:[NSError FTPKitErrorWithCode:425]];
            return;
        }
        const char *path = [self.handle.path cStringUsingEncoding:NSUTF8StringEncoding];
        int ret = 0;
        if (self.handle.type == FTPHandleTypeDirectory)
            ret = ftp_rmdir(path);
        else
            ret = ftp_delete(path);
        ftp_close();
        if (ret)
        {
            [self didFailWithError:[NSError FTPKitErrorWithCode:550]];
            return;
        }
        FKLogDebug(@"Deleted %@", self.handle.path);
        [self didUpdateStatus:NSLocalizedString(@"DEL Done", @"")];
        if ([self.delegate respondsToSelector:@selector(request:didDeletePath:)])
        {
            [self.delegate request:self didDeletePath:self.handle.path];
        }
    });
}

@end
