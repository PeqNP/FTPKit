#import "FTPSingleResourceRequest.h"

@interface FTPChmodRequest : FTPSingleResourceRequest

@property (nonatomic, assign) int mode;

- (BOOL)start;

@end