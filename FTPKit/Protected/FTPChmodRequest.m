
#import "ftplib.h"

#import "FTPChmodRequest.h"
#import "NSError+Additions.h"

@implementation FTPChmodRequest

@synthesize mode;

- (void)start
{
    if (mode < 0 || mode > 777)
    {
        // Put this an NSError+Additions
        // [NSError FTPKitErrorWithString:code:]
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"File mode value must be between 0 and 0777.", @"")
                                                             forKey:NSLocalizedDescriptionKey];
        NSError *error = [[NSError alloc] initWithDomain:FTPErrorDomain code:0 userInfo:userInfo];
        [self didFailWithError:error];
        return;
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queue, ^{
        NSString *command = [NSString stringWithFormat:@"SITE CHMOD %i %@", mode, self.handle.path];
        [self didUpdateStatus:command];
        netbuf *conn = [self connect];
        if (conn == NULL)
            return;
        BOOL success = [self sendCommand:command conn:conn];
        FtpQuit(conn);
        if (! success)
        {
            [self didFailWithError:[NSError FTPKitErrorWithCode:550]];
            return;
        }
        [self didUpdateStatus:NSLocalizedString(@"CHMOD Done", @"")];
        if ([self.delegate respondsToSelector:@selector(request:didChmodPath:)])
        {
            [self.delegate request:self didChmodPath:self.handle.path];
        }
    });
}

@end
