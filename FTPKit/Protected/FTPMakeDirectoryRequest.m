#import "FTPMakeDirectoryRequest.h"
#import "NSError+Additions.h"
#import "NSString+Additions.h"
#import "FTPKit+Protected.h"

@interface FTPMakeDirectoryRequest ()
@property (nonatomic, strong) NSOutputStream *networkStream;
@property (nonatomic, strong) NSURL *directoryURL;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSURL *remoteUrl;
@end

@implementation FTPMakeDirectoryRequest

@synthesize networkStream;
@synthesize directoryURL;
@synthesize name;

@synthesize remoteUrl;

- (instancetype)initWithCredentials:(FTPCredentials *)aCredentials handle:(FTPHandle *)handle
{
    self = [super initWithCredentials:aCredentials handle:handle];
    if (self)
    {
        self.networkStream = nil;
    }
    return self;
}


+ (FTPMakeDirectoryRequest *)requestWithDirectoryNamed:(NSString *)aName inLocation:(FTPCredentials *)aLocation
{
	return [[FTPMakeDirectoryRequest alloc] initWithDirectoryNamed:aName inLocation:aLocation];
}

- (id)initWithDirectoryNamed:(NSString *)aName inLocation:(FTPCredentials *)aLocation
{
    self = [super initWithCredentials:aLocation];
	if (self)
    {
		self.name = aName;
	}
	return self;
}

- (void)dealloc
{
    [self stop];
}

- (void)start
{
	if (self.networkStream)
        return;
	
    self.remoteUrl = [self.credentials urlForPath:self.path];
    if (! remoteUrl)
    {
		[self didFailWithMessage:NSLocalizedString(@"Invalid path", @"")];
        return;
	}
    
	[self didUpdateStatus:[NSString stringWithFormat:NSLocalizedString(@"MKD %@", @""), self.handle.path]];
	
	self.networkStream = (__bridge_transfer NSOutputStream *)CFWriteStreamCreateWithFTPURL(NULL, (__bridge CFURLRef)remoteUrl);
    if (! networkStream)
    {
        [self didFailWithMessage:NSLocalizedString(@"Failed to create write stream", @"")];
        return;
    }
	
	networkStream.delegate = self;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        [networkStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [networkStream open];
        [[NSRunLoop currentRunLoop] run];
    });
}

- (void)stop
{
	if (networkStream)
    {
        [networkStream close];
        [networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        networkStream.delegate = nil;
        self.networkStream = nil;
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSAssert(aStream == self.networkStream, @"MKD: Stream must be equal");
    
    switch (eventCode)
    {
        case NSStreamEventOpenCompleted:
        {
            [self didUpdateStatus:@"Opened connection"];
            break;
        }
        case NSStreamEventErrorOccurred:
        {
            CFStreamError err;
            err = CFWriteStreamGetError((__bridge CFWriteStreamRef)networkStream);
            if (err.domain == kCFStreamErrorDomainFTP)
            {
                [self didFailWithError:[NSError FTPKitErrorWithCode:(int)err.error]];
            }
            else
            {
                [self didFailWithError:[aStream streamError]];
            }
            break;
        }
        case NSStreamEventEndEncountered:
        {
#ifdef DEBUG
            FKLogDebug(@"Created dir: %@", self.handle.path);
#endif
            [self stop];
            [self didUpdateStatus:NSLocalizedString(@"MKD Done", @"")];
            if ([self.delegate respondsToSelector:@selector(request:didMakeDirectory:)])
            {
                [self.delegate request:self didMakeDirectory:self.handle.path];
            }
            break;
        }
        case NSStreamEventHasBytesAvailable:
        case NSStreamEventHasSpaceAvailable:
        default:
        {
            break;
        }
    }
}

@end
