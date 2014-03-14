
#import "FTPPutRequest.h"
#import "NSError+Additions.h"
#import "FTPKit+Protected.h"

@interface FTPPutRequest ()
@property (nonatomic, strong) NSString *localPath;
@property (nonatomic, strong) NSString *remotePath;
@end

@implementation FTPPutRequest

@synthesize localPath;
@synthesize remotePath;

+ (instancetype)requestWithCredentials:(FTPCredentials *)credentials uploadFile:(NSString *)localPath to:(NSString *)remotePath
{
    return [[FTPPutRequest alloc] initWithCredentials:credentials uploadFile:localPath to:remotePath];
}

- (instancetype)initWithCredentials:(FTPCredentials *)aCredentials uploadFile:(NSString *)aLocalPath to:(NSString *)aRemotePath
{
    self = [super initWithCredentials:aCredentials];
    if (self)
    {
        self.localPath = aLocalPath;
        self.remotePath = aRemotePath;
    }
    return self;
}

- (void)start
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queue, ^{
        [self didUpdateStatus:[NSString stringWithFormat:@"PUT %@", [localPath lastPathComponent]]];
        netbuf *conn = [self connect];
        if (conn == NULL)
            return;
        const char *input = [localPath cStringUsingEncoding:NSUTF8StringEncoding];
        const char *path = [remotePath cStringUsingEncoding:NSUTF8StringEncoding];
        // @todo Send w/ appropriate mode. FTPLIB_ASCII | FTPLIB_BINARY
        int stat = FtpPut(input, path, FTPLIB_BINARY, conn);
        FtpQuit(conn);
        if (stat == 0)
        {
            [self didFailWithError:[NSError FTPKitErrorWithCode:550]];
            return;
        }
        [self didUpdateStatus:NSLocalizedString(@"PUT Done", @"")];
        if ([self.delegate respondsToSelector:@selector(request:didUploadFile:to:)])
        {
            [self.delegate request:self didUploadFile:localPath to:remotePath];
        }
    });
}

@end
