#import <Foundation/Foundation.h>
#import "FTPRequest.h"
#import "FTPCredentials.h"
#import "FTPHandle.h"

@interface FTPGetRequest : FTPRequest <NSStreamDelegate>

+ (instancetype)requestWithCredentials:(FTPCredentials *)credentials downloadFile:(NSString *)remotePath to:(NSString *)localPath;
+ (instancetype)requestWithCredentials:(FTPCredentials *)credentials downloadHandle:(FTPHandle *)handle to:(NSString *)localPath;

- (instancetype)initWithCredentials:(FTPCredentials *)credentials downloadHandle:(FTPHandle *)handle to:(NSString *)localPath;

@end