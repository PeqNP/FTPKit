#import "FTPPutRequest.h"
#import "NSError+Additions.h"
#import "FTPKit+Protected.h"

@interface FTPPutRequest ()
{
    uint8_t buffer[kFTPKitRequestBufferSize];
    unsigned long long bytesUploaded;
	unsigned long long bytesTotal;
    size_t bufferOffset;
    size_t bufferLimit;
}

@property (nonatomic, strong) NSOutputStream *networkStream;
@property (nonatomic, strong) NSInputStream *fileStream;
@property (nonatomic, strong) NSString *localPath;
@property (nonatomic, strong) NSString *remotePath;
@property (nonatomic, strong) NSURL *remoteUrl;

- (void)didFinish;

@end


@implementation FTPPutRequest

@synthesize networkStream;
@synthesize fileStream;
@synthesize localPath;
@synthesize remotePath;
@synthesize remoteUrl;

+ (instancetype)requestWithCredentials:(FTPCredentials *)credentials uploadFile:(NSString *)localPath to:(NSString *)remotePath
{
    return [[FTPPutRequest alloc] initWithCredentials:credentials uploadFile:localPath to:remotePath];
}

- (instancetype)initWithCredentials:(FTPCredentials *)aCredentials uploadFile:(NSString *)aLocalPath to:(NSString *)aRemotePath
{
    self = [super initWithCredentials:aCredentials];
    if (self)
    {
        self.networkStream = nil;
        self.fileStream = nil;
        self.localPath = aLocalPath;
        self.remotePath = aRemotePath;
    }
    return self;
}

- (void)dealloc
{
    [self stop];
}

- (void)start
{
	if (self.networkStream != nil)
        return;
	
    self.remoteUrl = [self.credentials urlForPath:remotePath];
    if (! remoteUrl)
    {
		[self didFailWithMessage:NSLocalizedString(@"Invalid path", @"")];
        return;
	}
	self.remoteUrl = (__bridge_transfer NSURL *)CFURLCreateCopyAppendingPathComponent(NULL,
                                                                           (__bridge CFURLRef)remoteUrl,
                                                                           (__bridge CFStringRef)[localPath lastPathComponent],
                                                                           false);
	if (! remoteUrl)
    {
		[self didFailWithMessage:NSLocalizedString(@"Invalid path", @"")];
        return;
	}
	
    bufferLimit = 0;
    bufferOffset = 0;
    bytesUploaded = 0;
	bytesTotal = [[[NSFileManager defaultManager] attributesOfItemAtPath:localPath error:nil] fileSize];
	
	[self didUpdateStatus:[NSString stringWithFormat:@"PUT %@", localPath]];
	
	self.fileStream = [NSInputStream inputStreamWithFileAtPath:localPath];
    if (! fileStream)
    {
		[self didFailWithMessage:NSLocalizedString(@"Failed to create read stream", @"")];
        return;
	}
	[fileStream open];
	
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
    
	if (fileStream)
    {
		[fileStream close];
		self.fileStream = nil;
	}
}

- (void)didFinish
{
#ifdef DEBUG
    FKLogDebug(@"Uploaded: %@ to %@", localPath, remotePath);
#endif
    
	[self stop];
    [self didUpdateStatus:NSLocalizedString(@"PUT Done", @"")];
	if ([self.delegate respondsToSelector:@selector(request:didUploadFile:to:)])
    {
		[self.delegate request:self didUploadFile:localPath to:remotePath];
	}
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSAssert(aStream == self.networkStream, @"PUT: Stream must be equal");
	
    switch (eventCode)
    {
        case NSStreamEventOpenCompleted:
        {
            [self didUpdateStatus:NSLocalizedString(@"Opened connection", @"")];
            break;
        }
        case NSStreamEventHasSpaceAvailable:
        {
            [self didUpdateStatus:NSLocalizedString(@"Uploading", @"")];
            
            if (bufferOffset == bufferLimit)
            {
                NSInteger bytesRead = [self.fileStream read:self->buffer maxLength:kFTPKitRequestBufferSize];
                if (bytesRead == -1)
                {
                    [self didFailWithMessage:NSLocalizedString(@"Could not read from the local file", @"")];
                }
                else if (bytesRead == 0)
                {
                    [self didFinish];
					return; // 'break;' is probably equally effective.
                }
                else
                {
                    bufferOffset = 0;
                    bufferLimit  = bytesRead;
                }
            }
            
            if (bufferOffset != bufferLimit)
            {
                NSInteger bytesWritten = [self.networkStream write:&self->buffer[bufferOffset]
                                                         maxLength:bufferLimit - bufferOffset];
				bytesUploaded += bytesWritten;

                if (bytesWritten == -1)
                {
                    [self didFailWithMessage:NSLocalizedString(@"Failed to transfer data to server", @"")];
                }
                else
                {
                    bufferOffset += bytesWritten;
                    float progress = (float)bytesUploaded / (float)bytesTotal;
                    [self didUpdateProgress:progress];
                }
            }
            break;
        }
        case NSStreamEventErrorOccurred:
        {
            CFStreamError err;
            err = CFWriteStreamGetError((__bridge CFWriteStreamRef)self.networkStream);
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
            // We're the one responsible for "ending" the request. Therefore,
            // this will never get executed. It's here for sanity only.
            [self didFinish];
            break;
        }
        case NSStreamEventHasBytesAvailable:
        default:
            break;
    }
}

@end
