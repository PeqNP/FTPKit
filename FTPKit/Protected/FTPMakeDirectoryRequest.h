#import <Foundation/Foundation.h>
#import "FTPRequest.h"
#import "FTPCredentials.h"

@interface FTPMakeDirectoryRequest : FTPRequest <NSStreamDelegate>

+ (instancetype)requestWithCredentials:(FTPCredentials *)credentials path:(NSString *)path;

- (instancetype)initWithCredentials:(FTPCredentials *)location path:(NSString *)path;

@end