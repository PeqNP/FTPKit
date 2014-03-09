#import "NSError+Additions.h"

NSString *const FTPErrorDomain = @"FTPKit";

@implementation NSError (NSError_FTPKitAdditions)

+ (NSString *)FTPKitErrorMessageFromCode:(int)errorCode
{
    // http://en.wikipedia.org/wiki/List_of_FTP_server_return_codes
	NSString *message = NSLocalizedString(@"Undefined error has occurred", @"");
	switch (errorCode)
    {
		case 331:
			message = NSLocalizedString(@"User name okay, need password.", @"");
			break;
		case 332:
			message = NSLocalizedString(@"Need account for login.", @"");
			break;
		case 350:
			message = NSLocalizedString(@"Requested file action pending further information.", @"");
			break;
		case 421:
			message = NSLocalizedString(@"Service not available, closing control connection.", @"");
			break;
		case 425:
			message = NSLocalizedString(@"Can't open data connection.", @"");
			break;
		case 426:
			message = NSLocalizedString(@"Connection closed, transfer aborted.", @"");
			break;
		case 450:
			message = NSLocalizedString(@"Requested file action not taken. File unavailable (e.g., file busy).", @"");
			break;
		case 451:
			message = NSLocalizedString(@"Requested action aborted, local error in processing.", @"");
			break;
		case 452:
			message = NSLocalizedString(@"Requested action not taken. Insufficient storage space in system.", @"");
			break;
		case 500:
			message = NSLocalizedString(@"Syntax error, command unrecognized. This may include errors such as command line too long.", @"");
			break;
		case 501:
			message = NSLocalizedString(@"Syntax error in parameters or arguments.", @"");
			break;
		case 502:
			message = NSLocalizedString(@"Command not implemented.", @"");
			break;
		case 503:
			message = NSLocalizedString(@"Bad sequence of commands.", @"");
			break;
		case 504:
			message = NSLocalizedString(@"Command not implemented for that parameter.", @"");
			break;
		case 530:
			message = NSLocalizedString(@"User not logged in.", @"");
			break;
		case 532:
			message = NSLocalizedString(@"Need account for storing files.", @"");
			break;
		case 550:
			message = NSLocalizedString(@"Requested action not taken. File unavailable (e.g., file not found, no access).", @"");
			break;
		case 552:
			message = NSLocalizedString(@"Requested file action aborted, storage allocation exceeded", @"");
			break;
		default:
			break;
	}
	return message;
}

+ (NSError *)FTPKitErrorWithCode:(int)errorCode
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSError FTPKitErrorMessageFromCode:errorCode]
                                                         forKey:NSLocalizedDescriptionKey];
	return [[NSError alloc] initWithDomain:FTPErrorDomain code:errorCode userInfo:userInfo];
}

@end
