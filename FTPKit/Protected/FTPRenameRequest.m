
#import "ftplib.h"

#import "FTPRenameRequest.h"
#import "NSError+Additions.h"

@interface FTPRenameRequest()
@property (nonatomic, strong) NSString *sourcePath;
@property (nonatomic, strong) NSString *destPath;
@end

@implementation FTPRenameRequest

@synthesize sourcePath;
@synthesize destPath;

+ (instancetype)requestWithCredentials:(FTPCredentials *)credentials sourcePath:(NSString *)sourcePath destPath:(NSString *)destPath
{
    return [[self alloc] initWithCredentials:credentials sourcePath:sourcePath destPath:destPath];
}

- (instancetype)initWithCredentials:(FTPCredentials *)aCredentials sourcePath:(NSString *)aSourcePath destPath:(NSString *)aDestPath
{
    self = [super initWithCredentials:aCredentials];
    if (self)
    {
        self.sourcePath = aSourcePath;
        self.destPath = aDestPath;
    }
    return self;
}

- (BOOL)start
{
    [self didUpdateStatus:[NSString stringWithFormat:@"RNFR %@ RNTO %@", sourcePath, destPath]];
    netbuf *conn = [self connect];
    if (conn == NULL)
    {
        [self didFailWithError:[NSError FTPKitErrorWithCode:10060]];
        return NO;
    }
    const char *src = [sourcePath cStringUsingEncoding:NSUTF8StringEncoding];
    const char *dst = [destPath cStringUsingEncoding:NSUTF8StringEncoding];
    int stat = FtpRename(src, dst, conn);
    FtpQuit(conn);
    if (stat == 0)
    {
        [self didFailWithError:[NSError FTPKitErrorWithCode:550]];
        return NO;
    }
    [self didUpdateStatus:NSLocalizedString(@"Rename Done", @"")];
    return YES;
}

@end
