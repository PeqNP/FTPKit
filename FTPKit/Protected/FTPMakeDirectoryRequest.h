#import "FTPSingleResourceRequest.h"

@interface FTPMakeDirectoryRequest : FTPSingleResourceRequest <NSStreamDelegate>
- (BOOL)start;
@end