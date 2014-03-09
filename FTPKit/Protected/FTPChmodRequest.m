#import "FTPChmodRequest.h"
#import "NSError+Additions.h"
#import "FTPKit+Protected.h"

#import <sys/socket.h>
#import <sys/types.h>
#import <netinet/in.h>
#import <netdb.h>

@implementation FTPChmodRequest

@synthesize mode;

- (void)start
{
    if (mode < 0 || mode > 777)
    {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"File mode value must be between 0 and 777.", @"")
                                                             forKey:NSLocalizedDescriptionKey];
        NSError *error = [[NSError alloc] initWithDomain:FTPErrorDomain code:0 userInfo:userInfo];
        [self didFailWithError:error];
        return;
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queue, ^{
        
        BOOL success = YES;
        
        // @todo
        
        if (success)
        {
#ifdef DEBUG
            FKLogDebug(@"Permissions changed on %@ to %d", self.path, mode);
#endif
            
            [self didUpdateStatus:NSLocalizedString(@"CHMOD Done", @"")];
            if ([self.delegate respondsToSelector:@selector(request:didChmodFile:)])
            {
                [self.delegate request:self didChmodFile:self.path];
            }
        }
        else
        {
            [self didFailWithError:[NSError FTPKitErrorWithCode:0]];
        }
    });
}

@end
