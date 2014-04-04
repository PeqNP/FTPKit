
#import "FTPSingleResourceRequest.h"

@interface FTPListRequest : FTPSingleResourceRequest <NSStreamDelegate>

@property (nonatomic, assign) BOOL showHiddenItems;

- (NSArray *)start;

@end