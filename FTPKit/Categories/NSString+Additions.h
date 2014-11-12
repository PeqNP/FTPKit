
@interface NSString (NSString_FTPKitAdditions)

/**
 URL encode a string.
 
 @param string String to URL encode
 @return NSString Encoded URL string
 */
+ (NSString *)FTPKitURLEncodeString:(NSString *)string;

/**
 URL decode a string.
 
 @param string String to URL decode
 @return NSString Decoded URL string.
 */
+ (NSString *)FTPKitURLDecodeString:(NSString *)string;

- (NSString *)FTPKitURLEncodedString;
- (NSString *)FTPKitURLDecodedString;

- (BOOL)isIntegerValue;

@end