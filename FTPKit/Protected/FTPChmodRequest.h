#import "FTPSingleResourceRequest.h"
#import "FTPHandle.h"
#import "FTPCredentials.h"

@interface FTPChmodRequest : FTPSingleResourceRequest
@property (nonatomic, assign) int mode;
@end