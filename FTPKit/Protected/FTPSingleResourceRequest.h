
#import "FTPRequest.h"
#import "FTPHandle.h"

@interface FTPSingleResourceRequest : FTPRequest

@property (nonatomic, readonly) FTPHandle *handle;

+ (instancetype)requestWithCredentials:(FTPCredentials *)credentials handle:(FTPHandle *)handle;

- (instancetype)initWithCredentials:(FTPCredentials *)credentials handle:(FTPHandle *)handle;

@end
