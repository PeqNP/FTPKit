
#import "ftplib.h"

#import "FTPChmodRequest.h"
#import "NSError+Additions.h"

@implementation FTPChmodRequest

@synthesize mode;

- (BOOL)start
{
    if (mode < 0 || mode > 777)
    {
        // Put this an NSError+Additions
        // [NSError FTPKitErrorWithString:code:]
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"File mode value must be between 0 and 0777.", @"")
                                                             forKey:NSLocalizedDescriptionKey];
        NSError *error = [[NSError alloc] initWithDomain:FTPErrorDomain code:0 userInfo:userInfo];
        [self didFailWithError:error];
        return NO;
    }
    NSString *command = [NSString stringWithFormat:@"SITE CHMOD %i %@", mode, self.handle.path];
    [self didUpdateStatus:command];
    netbuf *conn = [self connect];
    if (conn == NULL)
    {
        [self didFailWithError:[NSError FTPKitErrorWithCode:10060]];
        return NO;
    }
    BOOL success = [self sendCommand:command conn:conn];
    FtpQuit(conn);
    if (! success)
    {
        [self didFailWithError:[NSError FTPKitErrorWithCode:550]];
        return NO;
    }
    [self didUpdateStatus:NSLocalizedString(@"CHMOD Done", @"")];
    return YES;
}

@end
