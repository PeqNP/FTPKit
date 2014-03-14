#import "FTPRequest.h"
#import "NSError+Additions.h"
#import "FTPKit+Protected.h"

@interface FTPRequest ()
@property (nonatomic, strong) FTPCredentials *credentials;
@end

@implementation FTPRequest

@synthesize credentials;

- (instancetype)initWithCredentials:(FTPCredentials *)aCredentials
{
    self = [super init];
    if (self)
    {
        self.credentials = aCredentials;
    }
    return self;
}

- (void)start
{
    // Nothing to do.
}

- (netbuf *)connect
{
    const char *host = [self.credentials.host cStringUsingEncoding:NSUTF8StringEncoding];
    const char *user = [self.credentials.username cStringUsingEncoding:NSUTF8StringEncoding];
    const char *pass = [self.credentials.password cStringUsingEncoding:NSUTF8StringEncoding];
    netbuf *conn;
    int stat = FtpConnect(host, &conn);
    if (stat == 0)
    {
        // @fixme We don't get the exact error code from the lib. Use a generic
        // connection error.
        [self didFailWithError:[NSError FTPKitErrorWithCode:10060]];
        return NULL;
    }
    stat = FtpLogin(user, pass, conn);
    if (stat == 0)
    {
        [self didFailWithError:[NSError FTPKitErrorWithCode:430]];
        FtpQuit(conn);
        return NULL;
    }
    return conn;
}

- (BOOL)sendCommand:(NSString *)command conn:(netbuf *)conn
{
    const char *cmd = [command cStringUsingEncoding:NSUTF8StringEncoding];
    if (!FtpSendCmd(cmd, '2', conn))
        return NO;
    return YES;
}

- (void)stop
{
    // Nothing to do.
}

- (void)cancel
{
    [self stop];
    [self didUpdateStatus:NSLocalizedString(@"Request Canceled", @"")];
	if ([self.delegate respondsToSelector:@selector(requestDidCancel:)])
    {
		[self.delegate requestDidCancel:self];
	}
}

// Protected methods.

- (void)didUpdateStatus:(NSString *)status
{
#ifdef DEBUG
    FKLogDebug(@"Status: %@", status);
#endif
	if ([self.delegate respondsToSelector:@selector(request:didUpdateStatus:)])
    {
		[self.delegate request:self didUpdateStatus:status];
	}
}

- (void)didUpdateProgress:(float)progress
{
    if ([self.delegate respondsToSelector:@selector(request:didUpdateProgress:)])
    {
		[self.delegate request:self didUpdateProgress:progress];
	}
}

- (void)didFailWithError:(NSError *)error
{
    FKLogError(@"Class (%@) didFailWithError (%@)", NSStringFromClass([self class]), error);
    [self stop];
	if ([self.delegate respondsToSelector:@selector(request:didFailWithError:)])
    {
		[self.delegate request:self didFailWithError:error];
	}
}

- (void)didFailWithMessage:(NSString *)message
{
    NSError *error = [NSError errorWithDomain:FTPErrorDomain
                                         code:502
                                     userInfo:[NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey]];
    [self didFailWithError:error];
}

@end
