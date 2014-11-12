#import "NSString+Additions.h"

@implementation NSString (NSString_FTPKitAdditions)

+ (NSString *)FTPKitURLEncodeString:(NSString *)unescaped
{
    NSString *result = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)unescaped, NULL, CFSTR("!*'();:@&=+$,?%#[]\" ") /* Removed '/' */, kCFStringEncodingUTF8);
    return result;
}

+ (NSString *)FTPKitURLDecodeString:(NSString *)string
{
    NSString *result = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef)string, CFSTR(""), kCFStringEncodingUTF8);
	return result;
}

- (NSString *)FTPKitURLEncodedString
{
    return [NSString FTPKitURLEncodeString:self];
}

- (NSString *)FTPKitURLDecodedString
{
    return [NSString FTPKitURLDecodeString:self];
}

- (BOOL)isIntegerValue
{
    NSScanner *scanner = [NSScanner scannerWithString:self];
    if ([scanner scanInteger:NULL]) {
        return [scanner isAtEnd];
    }
    return NO;
}

@end
