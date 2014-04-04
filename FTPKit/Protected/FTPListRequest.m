
#import "FTPListRequest.h"
#import "FTPHandle.h"
#import "NSError+Additions.h"
#import "FTPKit+Protected.h"

@interface FTPListRequest ()

@property (nonatomic, strong) NSMutableData *listData;
@property (nonatomic, strong) NSMutableArray *entries;
@property (nonatomic, strong) NSInputStream *networkStream;
@property (nonatomic, strong) NSURL *directoryURL;
@property (nonatomic, strong) NSURL *remoteUrl;

- (NSDictionary *)entryByReencodingNameInEntry:(NSDictionary *)entry encoding:(NSStringEncoding)newEncoding;
- (void)parseListData;

@end

@implementation FTPListRequest

@synthesize showHiddenItems;

@synthesize listData;
@synthesize entries;
@synthesize networkStream;
@synthesize directoryURL;
@synthesize remoteUrl;

- (void)dealloc
{
    [self stop];
}

- (NSArray *)start
{
	if (self.networkStream)
        return nil;
	
    [self didUpdateStatus:[NSString stringWithFormat:NSLocalizedString(@"LIST %@", @""), self.handle.path]];
	
    self.remoteUrl = [self.credentials urlForPath:self.handle.path];
    if (! remoteUrl)
    {
		[self didFailWithMessage:NSLocalizedString(@"Invalid path", @"")];
        return nil;
	}
    
	self.listData = [NSMutableData data];
	self.entries = [NSMutableArray array];
	
	self.networkStream = (__bridge_transfer NSInputStream *)CFReadStreamCreateWithFTPURL(NULL, (__bridge CFURLRef)remoteUrl);
	if (! networkStream)
    {
        [self didFailWithMessage:NSLocalizedString(@"Failed to create read stream", @"")];
        return nil;
    }
	
    [networkStream setProperty:(id)kCFBooleanFalse
                        forKey:(NSString *)kCFStreamPropertyFTPAttemptPersistentConnection];
	networkStream.delegate = self;
    [networkStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [networkStream open];
    [[NSRunLoop currentRunLoop] run];
    return nil;
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
    self.listData = nil;
}

- (NSDictionary *)entryByReencodingNameInEntry:(NSDictionary *)entry encoding:(NSStringEncoding)newEncoding
{
    // Convert to the preferred encoding. By default CF encodes the string
    // as MacRoman.
    NSData *nameData = nil;
    NSString *newName = nil;
    NSString *name = [entry objectForKey:(id)kCFFTPResourceName];
    if (name != nil)
    {
        nameData = [name dataUsingEncoding:NSMacOSRomanStringEncoding];
        if (nameData != nil)
        {
            newName = [[NSString alloc] initWithData:nameData encoding:newEncoding];
        }
    }
    
    // If the above failed, just return the entry unmodified.  If it succeeded,
    // make a copy of the entry and replace the name with the new name that we
    // calculated.
    NSDictionary *result = nil;
    if (newName == nil)
    {
        result = (NSDictionary *)entry;
    }
    else
    {
        NSMutableDictionary *newEntry = [NSMutableDictionary dictionaryWithDictionary:entry];
        [newEntry setObject:newName forKey:(id)kCFFTPResourceName];
        result = newEntry;
    }
    return result;
}

- (void)parseListData
{
    NSMutableArray *newEntries = [NSMutableArray array];
    NSUInteger offset = 0;
    
    do
    {
        CFDictionaryRef thisEntry = NULL;
        CFIndex bytesConsumed = CFFTPCreateParsedResourceListing(NULL,
                                                                 &((const uint8_t *) self.listData.bytes)[offset],
                                                                 self.listData.length - offset,
                                                                 &thisEntry);
        if (bytesConsumed > 0)
        {
            if (thisEntry != NULL)
            {
                NSDictionary *entry = [self entryByReencodingNameInEntry:(__bridge NSDictionary *)thisEntry encoding:NSUTF8StringEncoding];
                FTPHandle *ftpHandle = [FTPHandle handleAtPath:self.handle.path attributes:entry];
				if (! [ftpHandle.name hasPrefix:@"."] || showHiddenItems)
                {
					[newEntries addObject:ftpHandle];
				}
            }
            offset += bytesConsumed;
        }
        
        if (thisEntry != NULL)
        {
            CFRelease(thisEntry);
        }
        
        if (bytesConsumed == 0)
        {
            break;
        }
        else if (bytesConsumed < 0)
        {
            [self didFailWithMessage:NSLocalizedString(@"Failed to parse directory listing", @"")];
            break;
        }
        
    } while (YES);
	
    if (newEntries.count != 0)
    {
		[entries addObjectsFromArray:newEntries];
    }
    
    if (offset != 0)
    {
        [self.listData replaceBytesInRange:NSMakeRange(0, offset) withBytes:NULL length:0];
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSAssert(aStream == self.networkStream, @"LIST: Stream must be equal");
	
    switch (eventCode)
    {
        case NSStreamEventOpenCompleted:
        {
            [self didUpdateStatus:NSLocalizedString(@"Opened connection", @"")];
        } break;
        case NSStreamEventHasBytesAvailable:
        {
            NSInteger bytesRead;
            uint8_t buffer[kFTPKitRequestBufferSize];
            [self didUpdateStatus:NSLocalizedString(@"Receiving", @"")];
            
            bytesRead = [self.networkStream read:buffer maxLength:sizeof(buffer)];
            if (bytesRead == -1)
            {
                [self didFailWithMessage:NSLocalizedString(@"Could not read the listing from the remote server", @"")];
            }
            else if (bytesRead > 0)
            {
                [self.listData appendBytes:buffer length:bytesRead];
                [self parseListData];
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
            [self didUpdateStatus:NSLocalizedString(@"LIST Done", @"")];
            if ([self.delegate respondsToSelector:@selector(request:didList:)])
            {
                [self.delegate request:self didList:entries];
            }
        } break;
        case NSStreamEventHasSpaceAvailable:
        default:
			break;
    }
}

@end
