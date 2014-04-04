
@interface FTPCredentials : NSObject

@property (nonatomic, readonly) NSString *host;
@property (nonatomic, readonly) int port;
@property (nonatomic, readonly) NSString *username;
@property (nonatomic, readonly) NSString *password;

/**
 Factory: Create credentials used for login.
 
 @param host Host of server.
 @param port Server port.
 @param username Username used to connect to server.
 @param password User's password.
 @return FTPCredentials
 */
+ (instancetype)credentialsWithHost:(NSString *)host port:(int)port username:(NSString *)username password:(NSString *)password;

/**
 Create credentials used for login.
 
 @param host Host of server.
 @param port Server port.
 @param username Username used to connect to server.
 @param password User's password.
 @return FTPCredentials
 */
- (id)initWithHost:(NSString *)host port:(int)port username:(NSString *)username password:(NSString *)password;

/**
 Creates fully qualified FTP URL including schema, credentials and the absolute
 path to the resource.
 
 @param path Path to remote resource. The path should never contain schema, etc.
 @return NSURL URL for path.
 */
- (NSURL *)urlForPath:(NSString *)path;

@end