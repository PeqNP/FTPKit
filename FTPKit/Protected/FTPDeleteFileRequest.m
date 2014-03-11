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
        const char *host = [self.credentials.host cStringUsingEncoding:NSUTF8StringEncoding];
        const char *user = [self.credentials.username cStringUsingEncoding:NSUTF8StringEncoding];
        const char *pass = [self.credentials.password cStringUsingEncoding:NSUTF8StringEncoding];
        netbuf *nControl;
        int stat = FtpConnect(host, &nControl);
        if (stat == 0)
        {
            [self didFailWithError:[NSError FTPKitErrorWithCode:425]];
            return;
        }
        stat = FtpLogin(user, pass, nControl);
        if (stat == 0)
        {
            [self didFailWithError:[NSError FTPKitErrorWithCode:430]];
            FtpQuit(nControl);
            return;
        }
        const char *path = [self.handle.path cStringUsingEncoding:NSUTF8StringEncoding];
        if (self.handle.type == FTPHandleTypeDirectory)
            stat = FtpRmdir(path, nControl);
        else
            stat = FtpDelete(path, nControl);
        FtpQuit(nControl);
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
