
@interface NSString (NSString_FTPKitAdditions)

+ (NSString *)FTPKitURLEncodeString:(NSString *)string;
+ (NSString *)FTPKitURLDecodeString:(NSString *)string;

- (NSString *)FTPKitURLEncodedString;
- (NSString *)FTPKitURLDecodedString;

@end