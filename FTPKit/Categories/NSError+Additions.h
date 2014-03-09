
extern NSString *const FTPErrorDomain;

@interface NSError (NSError_FTPKitAdditions)
+ (NSError *)FTPKitErrorWithCode:(int)errorCode;
@end
