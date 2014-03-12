
#import "FTPGetRequest.h"
#import "NSError+Additions.h"
#import "FTPKit+Protected.h"

@interface FTPGetRequest ()
@property (nonatomic, strong) FTPHandle *handle;
@property (nonatomic, strong) NSString *localPath;
@end

@implementation FTPGetRequest

@synthesize handle;
@synthesize localPath;

+ (instancetype)requestWithCredentials:(FTPCredentials *)credentials downloadHandle:(FTPHandle *)handle to:(NSString *)localPath
{
    return [[self alloc] initWithCredentials:credentials downloadHandle:handle to:localPath];
}

- (instancetype)initWithCredentials:(FTPCredentials *)credentials downloadHandle:(FTPHandle *)aHandle to:(NSString *)aLocalPath
{
    self = [super initWithCredentials:credentials];
    if (self)
    {
        self.handle = aHandle;
        self.localPath = aLocalPath;
    }
    return self;
}

- (void)start
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queue, ^{
        [self didUpdateStatus:[NSString stringWithFormat:@"GET %@", handle.path]];
        netbuf *conn = [self connect];
        if (conn == NULL)
            return;
        const char *output = [localPath cStringUsingEncoding:NSUTF8StringEncoding];
        const char *path = [self.handle.path cStringUsingEncoding:NSUTF8StringEncoding];
        // @todo Send w/ appropriate mode. FTPLIB_ASCII | FTPLIB_BINARY
        int stat = FtpGet(output, path, FTPLIB_BINARY, conn);
        FtpQuit(conn);
        if (stat == 0)
        {
            [self didFailWithError:[NSError FTPKitErrorWithCode:550]];
            return;
        }
        [self didUpdateStatus:NSLocalizedString(@"GET Done", @"")];
        if ([self.delegate respondsToSelector:@selector(request:didDownloadFile:to:)])
        {
            [self.delegate request:self didDownloadFile:handle.path to:localPath];
        }
    });
}

@end
