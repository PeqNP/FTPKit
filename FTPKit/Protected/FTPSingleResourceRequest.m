#import "FTPSingleResourceRequest.h"

@interface FTPSingleResourceRequest()
@property (nonatomic, strong) FTPHandle *handle;
@end

@implementation FTPSingleResourceRequest

@synthesize handle;

+ (instancetype)requestWithCredentials:(FTPCredentials *)credentials handle:(FTPHandle *)handle
{
    return [[self alloc] initWithCredentials:credentials handle:handle];
}

- (instancetype)initWithCredentials:(FTPCredentials *)aCredentials handle:(FTPHandle *)aHandle
{
    self = [super initWithCredentials:aCredentials];
    if (self)
    {
        self.handle = aHandle;
    }
    return self;
}

@end
