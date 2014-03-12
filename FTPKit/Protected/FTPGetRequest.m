
#import "FTPGetRequest.h"
#import "NSError+Additions.h"
#import "FTPKit+Protected.h"

@interface FTPGetRequest ()
{
    unsigned long long bytesDownloaded;
	unsigned long long bytesTotal;
}

@property (nonatomic, strong) NSInputStream *networkStream;
@property (nonatomic, strong) NSOutputStream *fileStream;
@property (nonatomic, strong) FTPHandle *handle;
@property (nonatomic, strong) NSString *localPath;
@property (nonatomic, strong) NSURL *remoteUrl;

@end

@implementation FTPGetRequest

@synthesize delegate;
@synthesize fileStream;
@synthesize networkStream;
@synthesize handle;
@synthesize localPath;
@synthesize remoteUrl;

+ (instancetype)requestWithCredentials:(FTPCredentials *)credentials downloadHandle:(FTPHandle *)handle to:(NSString *)localPath
{
    return [[self alloc] initWithCredentials:credentials downloadHandle:handle to:localPath];
}

- (instancetype)initWithCredentials:(FTPCredentials *)credentials downloadHandle:(FTPHandle *)aHandle to:(NSString *)aLocalPath
{
    self = [super initWithCredentials:credentials];
    if (self)
    {
        self.networkStream = nil;
        self.fileStream = nil;
        self.handle = aHandle;
        self.localPath = aLocalPath;
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
	
    [self didUpdateStatus:[NSString stringWithFormat:@"GET %@", handle.path]];
	
    self.remoteUrl = [self.credentials urlForPath:handle.path];
	if (! remoteUrl)
    {
		[self didFailWithMessage:NSLocalizedString(@"Invalid path", @"")];
        return;
	}
    
    bytesTotal = self.handle.size;
	bytesDownloaded = 0;

	self.fileStream = [NSOutputStream outputStreamToFileAtPath:localPath append:NO];
    if (! fileStream)
    {
		[self didFailWithMessage:NSLocalizedString(@"Failed to open file for writing", @"")];
        return;
	}
	[fileStream open];
	
	self.networkStream = (__bridge_transfer NSInputStream *)CFReadStreamCreateWithFTPURL(NULL, (__bridge CFURLRef)remoteUrl);
    if (! networkStream)
    {
		[self didFailWithMessage:NSLocalizedString(@"Failed to create stream for reading", @"")];
        return;
	}
    
    // Do not run the stream logic on the main thread. In certain instances
    // the the run loop mode is changed and events associated to this stream
    // are never recieved. This also prevents intermittent EXC_BAD_ACCESS issues
    // from occuring.
    
    // These other commands may be necessary.
    //[self.networkStream setProperty:(id)kCFBooleanFalse
    //                         forKey:(id)kCFStreamPropertyFTPAttemptPersistentConnection];
    //[self.networkStream setProperty:(id)kCFBooleanTrue forKey:(id)kCFStreamPropertyShouldCloseNativeSocket];
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
        /*
         * From Apple's docs at: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSStream_Class/Reference/Reference.html#//apple_ref/occ/instm/NSStream/close
         *
         * Closing the stream terminates the flow of bytes and releases system
         * resources that were reserved for the stream when it was opened. If
         * the stream has been scheduled on a run loop, closing the stream
         * implicitly removes the stream from the run loop.
         */
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

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSAssert(aStream == self.networkStream, @"GET: Stream must be equal");
	
    switch (eventCode)
    {
        case NSStreamEventOpenCompleted:
        {
            [self didUpdateStatus:NSLocalizedString(@"Opened connection", @"")];
        } break;
        case NSStreamEventHasBytesAvailable:
        {
            [self didUpdateStatus:NSLocalizedString(@"Downloading", @"")];
            
            NSInteger bytesRead;
            uint8_t buffer[kFTPKitRequestBufferSize];
			
            if (bytesTotal > 0)
            {
                float progress = (float)bytesDownloaded / (float)bytesTotal;
                [self didUpdateProgress:progress];
            }
            
            bytesRead = [self.networkStream read:buffer maxLength:sizeof(buffer)];
            if (bytesRead == -1)
            {
                [self didFailWithMessage:NSLocalizedString(@"Network read error", @"")];
            }
            else if (bytesRead > 0)
            {
                NSInteger bytesWritten;
                NSInteger bytesWrittenSoFar = 0;
				bytesDownloaded += bytesRead;
                do
                {
                    bytesWritten = [self.fileStream write:&buffer[bytesWrittenSoFar] maxLength:bytesRead - bytesWrittenSoFar];
                    if (bytesWritten == -1)
                    {
                        [self didFailWithMessage:NSLocalizedString(@"File write error", @"")];
                        break;
                    }
                    else
                    {
                        bytesWrittenSoFar += bytesWritten;
                    }
                    
                } while (bytesWrittenSoFar != bytesRead);
            }
        } break;
        case NSStreamEventErrorOccurred:
        {
            CFStreamError err = CFReadStreamGetError((__bridge CFReadStreamRef)self.networkStream);
            if (err.domain == kCFStreamErrorDomainFTP)
            {
                [self didFailWithError:[NSError FTPKitErrorWithCode:(int)err.error]];
            }
            else
            {
                [self didFailWithError:[aStream streamError]];
            }
        } break;
        case NSStreamEventEndEncountered:
        {
            [self stop];
            [self didUpdateStatus:NSLocalizedString(@"GET Done", @"")];
            if ([self.delegate respondsToSelector:@selector(request:didDownloadFile:to:)])
            {
                [self.delegate request:self didDownloadFile:handle.path to:localPath];
            }
        } break;
        case NSStreamEventHasSpaceAvailable:
        default:
            break;
    }
}

@end
