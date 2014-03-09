#import <Foundation/Foundation.h>
#import "FTPRequest.h"
#import "FTPCredentials.h"

@interface FTPPutRequest : FTPRequest <NSStreamDelegate>

+ (instancetype)requestWithCredentials:(FTPCredentials *)credentials uploadFile:(NSString *)localPath to:(NSString *)remotePath;

- (instancetype)initWithCredentials:(FTPCredentials *)credentials uploadFile:(NSString *)localPath to:(NSString *)remotePath;

@end