#import <Foundation/Foundation.h>
#import "FTPSingleResourceRequest.h"
#import "FTPCredentials.h"

@interface FTPListRequest : FTPSingleResourceRequest <NSStreamDelegate>
@property (nonatomic, assign) BOOL showHiddenItems;
@end