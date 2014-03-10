#import "FTPKit.h"
#import "FTPMakeDirectoryRequest.h"
#import "NSError+Additions.h"
#import "NSString+Additions.h"
#import "FTPKit+Protected.h"

@implementation FTPMakeDirectoryRequest

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
        const char *directory = [self.handle.path cStringUsingEncoding:NSUTF8StringEncoding];
        int ret = ftp_mkdir(directory);
        ftp_close();
        if (ret)
        {
            [self didFailWithError:[NSError FTPKitErrorWithCode:550]];
            return;
        }
        FKLogDebug(@"Created directory %@", self.handle.path);
        [self didUpdateStatus:NSLocalizedString(@"MKD Done", @"")];
        if ([self.delegate respondsToSelector:@selector(request:didMakeDirectory:)])
        {
            [self.delegate request:self didMakeDirectory:self.handle.path];
        }
    });
}

@end
