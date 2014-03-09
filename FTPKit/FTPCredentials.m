#import "FTPCredentials.h"
#import "NSString+Additions.h"

@interface FTPCredentials()
@property (nonatomic, strong) NSString *host;
@property (nonatomic, assign) int port;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@end

@implementation FTPCredentials

@synthesize host;
@synthesize port;
@synthesize username;
@synthesize password;

+ (FTPCredentials *)credentialsWithHost:(NSString *)aHost port:(int)aPort username:(NSString *)aUsername password:(NSString *)aPassword
{
	return [[FTPCredentials alloc] initWithHost:aHost port:aPort username:aUsername password:aPassword];
}

- (id)initWithHost:(NSString *)aHost port:(int)aPort username:(NSString *)aUsername password:(NSString *)aPassword
{
    self = [super init];
	if (self)
    {
        self.host = aHost;
        self.port = aPort;
        self.username = aUsername;
        self.password = aPassword;
	}
	return self;
}

- (NSURL *)urlForPath:(NSString *)path
{
    // @todo encode username and password?
    NSString *scheme = [NSString stringWithFormat:@"ftp://%@:%@@%@:%d", username, password, host, port];
    NSString *decoded = [path FTPKitURLDecodedString];
    NSString *encoded = [decoded isEqualToString:path] ? [path FTPKitURLEncodedString] : path;
    NSURL *url = [NSURL URLWithString:[scheme stringByAppendingString:encoded]];
    return url;
}

@end
