#import "FTPKit.h"
#import "FTPRenameRequest.h"
#import "NSError+Additions.h"
#import "FTPKit+Protected.h"

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

- (void)start
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queue, ^{
        [self didUpdateStatus:[NSString stringWithFormat:@"RNFR %@ RNTO %@", sourcePath, destPath]];
        netbuf *conn = [self connect];
        if (conn == NULL)
            return;
        const char *src = [sourcePath cStringUsingEncoding:NSUTF8StringEncoding];
        const char *dst = [destPath cStringUsingEncoding:NSUTF8StringEncoding];
        int stat = FtpRename(src, dst, conn);
        FtpQuit(conn);
        if (stat == 0)
        {
            [self didFailWithError:[NSError FTPKitErrorWithCode:550]];
            return;
        }
        [self didUpdateStatus:NSLocalizedString(@"Rename Done", @"")];
        if ([self.delegate respondsToSelector:@selector(request:didRenamePath:to:)])
        {
            [self.delegate request:self didRenamePath:sourcePath to:destPath];
        }
    });
}

@end
