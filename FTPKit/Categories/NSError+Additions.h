
extern NSString *const FTPErrorDomain;

@interface NSError (NSError_FTPKitAdditions)

/**
 Returns an error for the respective FTP error code.
 
 @param errorCode FTP error code
 @return NSError Respective message for error code.
 */
+ (NSError *)FTPKitErrorWithCode:(int)errorCode;

+ (NSError *)FTPKitErrorWithResponse:(NSString *)response;

@end
