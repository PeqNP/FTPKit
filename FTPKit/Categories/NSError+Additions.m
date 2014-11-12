#import "NSError+Additions.h"
#import "NSString+Additions.h"

NSString *const FTPErrorDomain = @"FTPKit";

@implementation NSError (NSError_FTPKitAdditions)

+ (NSString *)FTPKitErrorMessageFromCode:(int)errorCode
{
    // http://en.wikipedia.org/wiki/List_of_FTP_server_return_codes
	NSString *message = NSLocalizedString(@"Undefined error has occurred.", @"");
	switch (errorCode) {
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
        case 430:
			message = NSLocalizedString(@"Invalid username or password.", @"");
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
        case 551:
			message = NSLocalizedString(@"Requested action aborted. Page type unknown.", @"");
			break;
		case 552:
			message = NSLocalizedString(@"Requested file action aborted, storage allocation exceeded.", @"");
			break;
        case 553:
			message = NSLocalizedString(@"Requested action not taken. File name not allowed.", @"");
			break;
        case 600:
			message = NSLocalizedString(@"Replies regarding confidentiality and integrity.", @"");
			break;
        case 631:
			message = NSLocalizedString(@"Integrity protected reply.", @"");
			break;
        case 632:
			message = NSLocalizedString(@"Confidentiality and integrity protected reply.", @"");
			break;
        case 633:
			message = NSLocalizedString(@"Confidentiality protected reply.", @"");
			break;
            // 1000 Series Common Winsock Error Codes
        case 10054:
			message = NSLocalizedString(@"Connection reset by peer. The connection was forcibly closed by the remote host.", @"");
			break;
        case 10060:
			message = NSLocalizedString(@"Cannot connect to remote server.", @"");
			break;
        case 10061:
			message = NSLocalizedString(@"Cannot connect to remote server. The connection is actively refused by the server.", @"");
			break;
        case 10066:
			message = NSLocalizedString(@"Directory not empty.", @"");
			break;
        case 10068:
			message = NSLocalizedString(@"Too many users, server is full.", @"");
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

+ (NSError *)FTPKitErrorWithResponse:(NSString *)response
{
    // Extract the code and message from the reponse message.
    // Ex: '500 Server error'
    NSMutableArray *components = [[response componentsSeparatedByString:@" "] mutableCopy];
    NSInteger code = 500;
    if ([components[0] isIntegerValue]) {
        code = [components[0] integerValue];
        [components removeObjectAtIndex:0];
    }
    NSString *message = [components componentsJoinedByString:@" "];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message
                                                         forKey:NSLocalizedDescriptionKey];
    return [[NSError alloc] initWithDomain:FTPErrorDomain code:code userInfo:userInfo];
}

@end
