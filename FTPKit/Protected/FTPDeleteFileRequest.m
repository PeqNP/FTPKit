#import "FTPDeleteFileRequest.h"
#import "NSError+Additions.h"
#import "FTPKit+Protected.h"

#import <CFNetwork/CFNetwork.h>

@implementation FTPDeleteFileRequest

- (void)start
{
	NSURL *url = [self.credentials urlForPath:self.path];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queue, ^{
        SInt32 status = 0;
        // I believe I need to use [NSFileManager removeItemAtUrl:NSURL]. However,
        // I don't know what the format of the URL should be to do this.
        BOOL success = CFURLDestroyResource((__bridge CFURLRef)url, &status);
        if (success)
        {
#ifdef DEBUG
            FKLogDebug(@"Deleted: %@", self.path);
#endif
            
            [self didUpdateStatus:NSLocalizedString(@"DEL Done", @"")];
            if ([self.delegate respondsToSelector:@selector(request:didDeleteFile:)])
            {
                [self.delegate request:self didDeleteFile:self.path];
            }
        }
        else
        {
            [self didFailWithError:[NSError FTPKitErrorWithCode:(int)status]];
        }
    });
}

@end
