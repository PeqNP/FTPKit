#import "FTPClient.h"

#import "NSError+Additions.h"
#import "FTPChmodRequest.h"
#import "FTPDeleteFileRequest.h"
#import "FTPGetRequest.h"
#import "FTPListRequest.h"
#import "FTPMakeDirectoryRequest.h"
#import "FTPPutRequest.h"
#import "FTPRenameRequest.h"

@interface FTPClient ()

/** Credentials used to login to the server. */
@property (nonatomic, strong) FTPCredentials* credentials;

/** Queued requests. */
@property (nonatomic, strong) NSMutableArray *requests;

/** Queue used to enforce requests to process in synchronous order. */
@property (nonatomic, strong) dispatch_queue_t queue;

/** The last error encountered. */
@property (nonatomic, strong) NSError *lastError;

/**
 Create connection to FTP server.
 
 @return netbuf The connection to the FTP server on success. NULL otherwise.
 */
- (netbuf *)connect;

/**
 Send arbitrary command to the FTP server.
 
 @param command Command to send to the FTP server.
 @param netbuf Connection to FTP server.
 @return BOOL YES on success. NO otherwise.
 */
- (BOOL)sendCommand:(NSString *)command conn:(netbuf *)conn;

@end

@implementation FTPClient

@synthesize credentials;
@synthesize requests;

+ (FTPClient *)clientWithCredentials:(FTPCredentials *)credentials
{
	return [[FTPClient alloc] initWithCredentials:credentials];
}

+ (FTPClient *)clientWithHost:(NSString *)host port:(int)port username:(NSString *)username password:(NSString *)password
{
	return [[FTPClient alloc] initWithHost:host port:port username:username password:password];
}

- (instancetype)initWithCredentials:(FTPCredentials *)aLocation
{
    self = [super init];
	if (self)
    {
		self.credentials = aLocation;
        self.requests = [[NSMutableArray alloc] init];
        self.queue = dispatch_queue_create("NMSFTPQueue", DISPATCH_QUEUE_SERIAL);
	}
	return self;
}

- (instancetype)initWithHost:(NSString *)host port:(int)port username:(NSString *)username password:(NSString *)password
{
    FTPCredentials *creds = [FTPCredentials credentialsWithHost:host port:port username:username password:password];
	return [self initWithCredentials:creds];
}

- (NSArray *)listContentsAtPath:(NSString *)path showHiddenFiles:(BOOL)showHiddenFiles
{
    FTPHandle *hdl = [FTPHandle handleAtPath:path type:FTPHandleTypeDirectory];
    return [self listContentsAtHandle:hdl showHiddenFiles:showHiddenFiles];
}

- (void)listContentsAtPath:(NSString *)path showHiddenFiles:(BOOL)showHiddenFiles success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
    FTPHandle *hdl = [FTPHandle handleAtPath:path type:FTPHandleTypeDirectory];
    [self listContentsAtHandle:hdl showHiddenFiles:showHiddenFiles success:success failure:failure];
}

- (NSArray *)listContentsAtHandle:(FTPHandle *)handle showHiddenFiles:(BOOL)showHiddenFiles
{
    // @todo FTPListRequest
    return nil;
}

- (void)listContentsAtHandle:(FTPHandle *)handle showHiddenFiles:(BOOL)showHiddenFiles success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
    // @todo
}

- (void)downloadFile:(NSString *)remotePath to:(NSString *)localPath progress:(BOOL (^)(NSUInteger, NSUInteger))progress success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    [self downloadHandle:[FTPHandle handleAtPath:remotePath type:FTPHandleTypeFile]  to:localPath progress:progress success:success failure:failure];
}

- (void)downloadHandle:(FTPHandle *)handle to:(NSString *)localPath progress:(BOOL (^)(NSUInteger, NSUInteger))progress success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    // @todo FTPGetRequest
}

- (void)uploadFile:(NSString *)localPath to:(NSString *)remotePath progress:(BOOL (^)(NSUInteger, NSUInteger))progress success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
	// @todo FTPPutRequest
}

- (BOOL)createDirectoryAtPath:(NSString *)remotePath
{
    return [self createDirectoryAtHandle:[FTPHandle handleAtPath:remotePath type:FTPHandleTypeDirectory]];
}

- (void)createDirectoryAtPath:(NSString *)remotePath success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    [self createDirectoryAtHandle:[FTPHandle handleAtPath:remotePath type:FTPHandleTypeDirectory] success:success failure:failure];
}

- (BOOL)createDirectoryAtHandle:(FTPHandle *)handle
{
    // @todo FTPMakeDirectoryRequest
    return YES;
}

- (void)createDirectoryAtHandle:(FTPHandle *)handle success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
	// @todo
}

- (BOOL)deleteDirectoryAtPath:(NSString *)remotePath
{
    return [self deleteHandle:[FTPHandle handleAtPath:remotePath type:FTPHandleTypeDirectory]];
}

- (void)deleteDirectoryAtPath:(NSString *)remotePath success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    [self deleteHandle:[FTPHandle handleAtPath:remotePath type:FTPHandleTypeDirectory] success:success failure:failure];
}

- (BOOL)deleteFileAtPath:(NSString *)remotePath
{
    return [self deleteHandle:[FTPHandle handleAtPath:remotePath type:FTPHandleTypeFile]];
}

- (void)deleteFileAtPath:(NSString *)remotePath success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    [self deleteHandle:[FTPHandle handleAtPath:remotePath type:FTPHandleTypeFile] success:success failure:failure];
}

- (BOOL)deleteHandle:(FTPHandle *)handle
{
    // @todo FTPDeleteFileRequest
	return YES;
}

- (void)deleteHandle:(FTPHandle *)handle success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    // @todo
}

- (BOOL)chmodPath:(NSString *)remotePath toMode:(int)mode
{
    return [self chmodHandle:[FTPHandle handleAtPath:remotePath type:FTPHandleTypeUnknown] toMode:mode];
}

- (void)chmodPath:(NSString *)remotePath toMode:(int)mode success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    [self chmodHandle:[FTPHandle handleAtPath:remotePath type:FTPHandleTypeUnknown] toMode:mode success:success failure:failure];
}

- (BOOL)chmodHandle:(FTPHandle *)handle toMode:(int)mode
{
    if (mode < 0 || mode > 777)
    {
        // Put this an NSError+Additions
        // [NSError FTPKitErrorWithString:code:]
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"File mode value must be between 0 and 0777.", @"")
                                                             forKey:NSLocalizedDescriptionKey];
        self.lastError = [[NSError alloc] initWithDomain:FTPErrorDomain code:0 userInfo:userInfo];
        return NO;
    }
    NSString *command = [NSString stringWithFormat:@"SITE CHMOD %i %@", mode, handle.path];
    netbuf *conn = [self connect];
    if (conn == NULL)
    {
        self.lastError = [NSError FTPKitErrorWithCode:10060];
        return NO;
    }
    BOOL success = [self sendCommand:command conn:conn];
    FtpQuit(conn);
    if (! success)
    {
        self.lastError = [NSError FTPKitErrorWithCode:550];
        return NO;
    }
    return YES;
}

- (void)chmodHandle:(FTPHandle *)handle toMode:(int)mode success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    dispatch_async(_queue, ^{
        BOOL ret = [self chmodHandle:handle toMode:mode];
        if (ret && success)
        {
            success();
        }
        else
        {
            failure(_lastError);
        }
    });
}

- (BOOL)renamePath:(NSString *)sourcePath to:(NSString *)destPath
{
    // @todo FTPRenameRequest
    return YES;
}

- (void)renamePath:(NSString *)sourcePath to:(NSString *)destPath success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    // @todo
}

/** Private Methods */

- (netbuf *)connect
{
    const char *host = [self.credentials.host cStringUsingEncoding:NSUTF8StringEncoding];
    const char *user = [self.credentials.username cStringUsingEncoding:NSUTF8StringEncoding];
    const char *pass = [self.credentials.password cStringUsingEncoding:NSUTF8StringEncoding];
    netbuf *conn;
    int stat = FtpConnect(host, &conn);
    if (stat == 0)
    {
        // @fixme We don't get the exact error code from the lib. Use a generic
        // connection error.
        self.lastError = [NSError FTPKitErrorWithCode:10060];
        return NULL;
    }
    stat = FtpLogin(user, pass, conn);
    if (stat == 0)
    {
        self.lastError = [NSError FTPKitErrorWithCode:430];
        FtpQuit(conn);
        return NULL;
    }
    return conn;
}

- (BOOL)sendCommand:(NSString *)command conn:(netbuf *)conn
{
    const char *cmd = [command cStringUsingEncoding:NSUTF8StringEncoding];
    if (!FtpSendCmd(cmd, '2', conn))
    {
        self.lastError = [NSError FTPKitErrorWithCode:451];
        return NO;
    }
    return YES;
}

/**
- (void)didFailWithMessage:(NSString *)message
{
    NSError *error = [NSError errorWithDomain:FTPErrorDomain
                                         code:502
                                     userInfo:[NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey]];
    [self didFailWithError:error];
}
 */

@end
