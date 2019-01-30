#import "FTPCredentials.h"
//#import "NSString+Additions.h"

@interface FTPCredentials()
@property (nonatomic, strong) NSString *host;
@property (nonatomic, assign) int port;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@end

@implementation FTPCredentials

+ (instancetype)credentialsWithHost:(NSString *)aHost port:(int)aPort username:(NSString *)aUsername password:(NSString *)aPassword
{
   return [[self alloc] initWithHost:aHost port:aPort username:aUsername password:aPassword];
}

- (id)initWithHost:(NSString *)aHost port:(int)aPort username:(NSString *)aUsername password:(NSString *)aPassword
{
   self = [super init];
   if (self) {
      self.host = aHost;
      self.port = aPort < 1 ? 21 : aPort;
      self.username = aUsername;
      self.password = aPassword;
   }
   return self;
}

- (NSURL *)urlForPath:(NSString *)path
{
   // @todo encode username and password?
   NSString *scheme = [NSString stringWithFormat:@"ftp://%@:%@@%@:%d", _username, _password, _host, _port];
   NSString *decoded = [path stringByRemovingPercentEncoding];
//   NSString *decoded = [path FTPKitURLDecodedString];
   if ( [decoded isEqualToString:path] )
      return [NSURL URLWithString:[scheme stringByAppendingString:[path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]]];
   return [NSURL URLWithString:[scheme stringByAppendingString:path]];
}

@end
