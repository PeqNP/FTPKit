
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

- (BOOL)start
{
    [self didUpdateStatus:[NSString stringWithFormat:@"GET %@", handle.path]];
    netbuf *conn = [self connect];
    if (conn == NULL)
    {
        [self didFailWithError:[NSError FTPKitErrorWithCode:10060]];
        return NO;
    }
    const char *output = [localPath cStringUsingEncoding:NSUTF8StringEncoding];
    const char *path = [self.handle.path cStringUsingEncoding:NSUTF8StringEncoding];
    // @todo Send w/ appropriate mode. FTPLIB_ASCII | FTPLIB_BINARY
    int stat = FtpGet(output, path, FTPLIB_BINARY, conn);
    FtpQuit(conn);
    if (stat == 0)
    {
        [self didFailWithError:[NSError FTPKitErrorWithCode:550]];
        return NO;
    }
    [self didUpdateStatus:NSLocalizedString(@"GET Done", @"")];
    return YES;
}

@end
