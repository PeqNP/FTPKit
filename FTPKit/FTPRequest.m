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
#ifdef DEBUG
    FKLogError(@"Class (%@) didFailWithError (%@)", NSStringFromClass([self class]), error);
#endif
    
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
