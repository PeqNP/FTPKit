
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

- (BOOL)start
{
    [self didUpdateStatus:[NSString stringWithFormat:@"PUT %@", [localPath lastPathComponent]]];
    netbuf *conn = [self connect];
    if (conn == NULL)
    {
        [self didFailWithError:[NSError FTPKitErrorWithCode:10060]];
        return NO;
    }
    const char *input = [localPath cStringUsingEncoding:NSUTF8StringEncoding];
    const char *path = [remotePath cStringUsingEncoding:NSUTF8StringEncoding];
    // @todo Send w/ appropriate mode. FTPLIB_ASCII | FTPLIB_BINARY
    int stat = FtpPut(input, path, FTPLIB_BINARY, conn);
    FtpQuit(conn);
    if (stat == 0)
    {
        [self didFailWithError:[NSError FTPKitErrorWithCode:550]];
        return NO;
    }
    [self didUpdateStatus:NSLocalizedString(@"PUT Done", @"")];
    return YES;
}

@end
