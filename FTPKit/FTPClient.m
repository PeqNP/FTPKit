#import "ftplib.h"
#import "FTPKit+Protected.h"
#import "FTPClient.h"
#import "NSError+Additions.h"

@interface FTPClient ()

@property (nonatomic, strong) FTPCredentials* credentials;

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

/**
 Returns a URL that can be used to write temporary data to.
 
 Make sure to remove the file after you are done using it!
 
 @return String to temporary path.
 */
- (NSString *)temporaryUrl;

- (NSDictionary *)entryByReencodingNameInEntry:(NSDictionary *)entry encoding:(NSStringEncoding)newEncoding;

/**
 Parse data returned from FTP LIST command.
 
 @param data Bytes returned from server containing directory listing.
 @param handle Parent directory handle.
 @param showHiddenFiles Ignores hiddent files if YES. Otherwise returns all files.
 @return List of FTPHandle objects.
 */
- (NSArray *)parseListData:(NSData *)data handle:(FTPHandle *)handle showHiddentFiles:(BOOL)showHiddenFiles;

/**
 Sets lastError w/ 'message' as description and error code 502.
 
 @param message Description to set to last error.
 */
- (void)failedWithMessage:(NSString *)message;

/**
 Convenience method that wraps failure(error) in dispatch_async(main_queue)
 and ensures that the error is copied before sending back to callee -- to ensure
 it doesn't get nil'ed out by the next command before the callee has a chance
 to read the error.
 */
- (void)returnFailure:(void (^)(NSError *error))failure;

/**
 URL encode a path.
 
 This method is used only on _existing_ files on the FTP server.
 
 @param path The path to URL encode.
 */
- (NSString *)urlEncode:(NSString *)path;

@end

@implementation FTPClient

+ (instancetype)clientWithCredentials:(FTPCredentials *)credentials
{
	return [[self alloc] initWithCredentials:credentials];
}

+ (instancetype)clientWithHost:(NSString *)host port:(int)port username:(NSString *)username password:(NSString *)password
{
	return [[self alloc] initWithHost:host port:port username:username password:password];
}

- (instancetype)initWithCredentials:(FTPCredentials *)aLocation
{
    self = [super init];
	if (self) {
		self.credentials = aLocation;
        self.queue = dispatch_queue_create("com.upstart-illustration-llc.FTPKitQueue", DISPATCH_QUEUE_SERIAL);
	}
	return self;
}

- (instancetype)initWithHost:(NSString *)host port:(int)port username:(NSString *)username password:(NSString *)password
{
    FTPCredentials *creds = [FTPCredentials credentialsWithHost:host port:port username:username password:password];
	return [self initWithCredentials:creds];
}

- (NSString *)urlEncode:(NSString *)path
{
    return [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (long long int)fileSizeAtPath:(NSString *)path
{
    netbuf *conn = [self connect];
    if (conn == NULL)
        return -1;
    const char *cPath = [[self urlEncode:path] cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned int bytes;
    int stat = FtpSize(cPath, &bytes, FTPLIB_BINARY, conn);
    FtpQuit(conn);
    if (stat == 0) {
        FKLogError(@"File most likely does not exist %@", path);
        return -1;
    }
    FKLogDebug(@"%@ bytes %d", path, bytes);
    return (long long int)bytes;
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
    netbuf *conn = [self connect];
    if (conn == NULL)
        return nil;
    const char *path = [[self urlEncode:handle.path] cStringUsingEncoding:NSUTF8StringEncoding];
    NSString *tmpPath = [self temporaryUrl];
    const char *output = [tmpPath cStringUsingEncoding:NSUTF8StringEncoding];
    int stat = FtpDir(output, path, conn);
    NSString *response = [NSString stringWithCString:FtpLastResponse(conn) encoding:NSUTF8StringEncoding];
    FtpQuit(conn);
    if (stat == 0) {
        self.lastError = [NSError FTPKitErrorWithResponse:response];
        return nil;
    }
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:tmpPath options:NSDataReadingUncached error:&error];
    if (error) {
        FKLogError(@"Error: %@", error.localizedDescription);
        self.lastError = error;
        return nil;
    }
    /**
     Please note: If there are no contents in the folder OR if the folder does
     not exist data.bytes _will_ be 0. Therefore, you can not use this method to
     determine if a directory exists!
     */
    [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:&error];
    // Log the error, but do not fail.
    if (error) {
        FKLogError(@"Failed to remove tmp file. Error: %@", error.localizedDescription);
    }
    NSArray *files = [self parseListData:data handle:handle showHiddentFiles:showHiddenFiles];
    return files; // If files == nil, method will set the lastError.
}

- (void)listContentsAtHandle:(FTPHandle *)handle showHiddenFiles:(BOOL)showHiddenFiles success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
    dispatch_async(_queue, ^{
        NSArray *contents = [self listContentsAtHandle:handle showHiddenFiles:showHiddenFiles];
        if (contents && success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success(contents);
            });
        } else if (! contents && failure) {
            [self returnFailure:failure];
        }
    });
}

- (BOOL)downloadFile:(NSString *)remotePath to:(NSString *)localPath progress:(BOOL (^)(NSUInteger, NSUInteger))progress
{
    return [self downloadHandle:[FTPHandle handleAtPath:remotePath type:FTPHandleTypeFile] to:localPath progress:progress];
}

- (void)downloadFile:(NSString *)remotePath to:(NSString *)localPath progress:(BOOL (^)(NSUInteger, NSUInteger))progress success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    [self downloadHandle:[FTPHandle handleAtPath:remotePath type:FTPHandleTypeFile]  to:localPath progress:progress success:success failure:failure];
}

- (BOOL)downloadHandle:(FTPHandle *)handle to:(NSString *)localPath progress:(BOOL (^)(NSUInteger, NSUInteger))progress
{
    netbuf *conn = [self connect];
    if (conn == NULL)
        return NO;
    const char *output = [localPath cStringUsingEncoding:NSUTF8StringEncoding];
    const char *path = [[self urlEncode:handle.path] cStringUsingEncoding:NSUTF8StringEncoding];
    // @todo Send w/ appropriate mode. FTPLIB_ASCII | FTPLIB_BINARY
    int stat = FtpGet(output, path, FTPLIB_BINARY, conn);
    NSString *response = [NSString stringWithCString:FtpLastResponse(conn) encoding:NSUTF8StringEncoding];
    // @todo Use 'progress' block.
    FtpQuit(conn);
    if (stat == 0) {
        self.lastError = [NSError FTPKitErrorWithResponse:response];
        return NO;
    }
    return YES;
}

- (void)downloadHandle:(FTPHandle *)handle to:(NSString *)localPath progress:(BOOL (^)(NSUInteger, NSUInteger))progress success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    dispatch_async(_queue, ^{
        BOOL ret = [self downloadHandle:handle to:localPath progress:progress];
        if (ret && success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success();
            });
        } else if (! ret && failure) {
            [self returnFailure:failure];
        }
    });
}

- (BOOL)uploadFile:(NSString *)localPath to:(NSString *)remotePath progress:(BOOL (^)(NSUInteger, NSUInteger))progress
{
    netbuf *conn = [self connect];
    if (conn == NULL)
        return NO;
    const char *input = [localPath cStringUsingEncoding:NSUTF8StringEncoding];
    const char *path = [remotePath cStringUsingEncoding:NSUTF8StringEncoding];
    // @todo Send w/ appropriate mode. FTPLIB_ASCII | FTPLIB_BINARY
    int stat = FtpPut(input, path, FTPLIB_BINARY, conn);
    // @todo Use 'progress' block.
    NSString *response = [NSString stringWithCString:FtpLastResponse(conn) encoding:NSUTF8StringEncoding];
    FtpQuit(conn);
    if (stat == 0) {
        // Invalid path, wrong permissions, etc. Make sure that permissions are
        // set corectly on the path AND the path of the initialPath is correct.
        self.lastError = [NSError FTPKitErrorWithResponse:response];
        return NO;
    }
    return YES;
}

- (void)uploadFile:(NSString *)localPath to:(NSString *)remotePath progress:(BOOL (^)(NSUInteger, NSUInteger))progress success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    dispatch_async(_queue, ^{
        BOOL ret = [self uploadFile:localPath to:remotePath progress:progress];
        if (ret && success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success();
            });
        } else if (! ret && failure) {
            [self returnFailure:failure];
        }
    });
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
    netbuf *conn = [self connect];
    if (conn == NULL)
        return NO;
    const char *path = [handle.path cStringUsingEncoding:NSUTF8StringEncoding];
    int stat = FtpMkdir(path, conn);
    NSString *response = [NSString stringWithCString:FtpLastResponse(conn) encoding:NSUTF8StringEncoding];
    FtpQuit(conn);
    if (stat == 0) {
        self.lastError = [NSError FTPKitErrorWithResponse:response];
        return NO;
    }
    return YES;
}

- (void)createDirectoryAtHandle:(FTPHandle *)handle success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
	dispatch_async(_queue, ^{
        BOOL ret = [self createDirectoryAtHandle:handle];
        if (ret && success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success();
            });
        } else if (! ret && failure) {
            [self returnFailure:failure];
        }
    });
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
    netbuf *conn = [self connect];
    if (conn == NULL)
        return NO;
    const char *path = [[self urlEncode:handle.path] cStringUsingEncoding:NSUTF8StringEncoding];
    int stat = 0;
    if (handle.type == FTPHandleTypeDirectory)
        stat = FtpRmdir(path, conn);
    else
        stat = FtpDelete(path, conn);
    NSString *response = [NSString stringWithCString:FtpLastResponse(conn) encoding:NSUTF8StringEncoding];
    FtpQuit(conn);
    if (stat == 0) {
        self.lastError = [NSError FTPKitErrorWithResponse:response];
        return NO;
    }
    return YES;
}

- (void)deleteHandle:(FTPHandle *)handle success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    dispatch_async(_queue, ^{
        BOOL ret = [self deleteHandle:handle];
        if (ret && success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success();
            });
        } else if (! ret && failure) {
            [self returnFailure:failure];
        }
    });
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
    if (mode < 0 || mode > 777) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"File mode value must be between 0 and 0777.", @"")
                                                             forKey:NSLocalizedDescriptionKey];
        self.lastError = [[NSError alloc] initWithDomain:FTPErrorDomain code:0 userInfo:userInfo];
        return NO;
    }
    NSString *command = [NSString stringWithFormat:@"SITE CHMOD %i %@", mode, [self urlEncode:handle.path]];
    netbuf *conn = [self connect];
    if (conn == NULL)
        return NO;
    BOOL success = [self sendCommand:command conn:conn];
    NSString *response = [NSString stringWithCString:FtpLastResponse(conn) encoding:NSUTF8StringEncoding];
    FtpQuit(conn);
    if (! success) {
        self.lastError = [NSError FTPKitErrorWithResponse:response];
        return NO;
    }
    return YES;
}

- (void)chmodHandle:(FTPHandle *)handle toMode:(int)mode success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    dispatch_async(_queue, ^{
        BOOL ret = [self chmodHandle:handle toMode:mode];
        if (ret && success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success();
            });
        } else if (! ret && failure) {
            [self returnFailure:failure];
        }
    });
}

- (BOOL)renamePath:(NSString *)sourcePath to:(NSString *)destPath
{
    netbuf *conn = [self connect];
    if (conn == NULL)
        return NO;
    const char *src = [[self urlEncode:sourcePath] cStringUsingEncoding:NSUTF8StringEncoding];
    // @note The destination path does not need to be URL encoded. In fact, if
    // it is, the filename will include the percent escaping!
    const char *dst = [destPath cStringUsingEncoding:NSUTF8StringEncoding];
    int stat = FtpRename(src, dst, conn);
    NSString *response = [NSString stringWithCString:FtpLastResponse(conn) encoding:NSUTF8StringEncoding];
    FtpQuit(conn);
    if (stat == 0) {
        self.lastError = [NSError FTPKitErrorWithResponse:response];
        return NO;
    }
    return YES;
}

- (void)renamePath:(NSString *)sourcePath to:(NSString *)destPath success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    dispatch_async(_queue, ^{
        BOOL ret = [self renamePath:sourcePath to:destPath];
        if (ret && success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success();
            });
        } else if (! ret && failure) {
            [self returnFailure:failure];
        }
    });
}

- (BOOL)copyPath:(NSString *)sourcePath to:(NSString *)destPath
{
    NSString *tmpPath = [self temporaryUrl];
    BOOL success = [self downloadFile:sourcePath to:tmpPath progress:NULL];
    if (! success)
        return NO;
    success = [self uploadFile:tmpPath to:destPath progress:NULL];
    // Remove file.
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:&error];
    // Log the error, but do not fail.
    if (error) {
        FKLogError(@"Failed to remove tmp file. Error: %@", error.localizedDescription);
    }
    if (! success)
        return NO;
    return YES;
}

- (void)copyPath:(NSString *)sourcePath to:(NSString *)destPath success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    dispatch_async(_queue, ^{
        BOOL ret = [self copyPath:sourcePath to:destPath];
        if (ret && success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success();
            });
        } else if (! ret && failure) {
            [self returnFailure:failure];
        }
    });
}

/** Private Methods */

- (netbuf *)connect
{
    self.lastError = nil;
    const char *host = [_credentials.host cStringUsingEncoding:NSUTF8StringEncoding];
    const char *user = [_credentials.username cStringUsingEncoding:NSUTF8StringEncoding];
    const char *pass = [_credentials.password cStringUsingEncoding:NSUTF8StringEncoding];
    netbuf *conn;
    int stat = FtpConnect(host, &conn);
    if (stat == 0) {
        // @fixme We don't get the exact error code from the lib. Use a generic
        // connection error.
        self.lastError = [NSError FTPKitErrorWithCode:10060];
        return NULL;
    }
    stat = FtpLogin(user, pass, conn);
    if (stat == 0) {
        NSString *response = [NSString stringWithCString:FtpLastResponse(conn) encoding:NSUTF8StringEncoding];
        self.lastError = [NSError FTPKitErrorWithResponse:response];
        FtpQuit(conn);
        return NULL;
    }
    return conn;
}

- (BOOL)sendCommand:(NSString *)command conn:(netbuf *)conn
{
    const char *cmd = [command cStringUsingEncoding:NSUTF8StringEncoding];
    if (!FtpSendCmd(cmd, '2', conn)) {
        NSString *response = [NSString stringWithCString:FtpLastResponse(conn) encoding:NSUTF8StringEncoding];
        self.lastError = [NSError FTPKitErrorWithResponse:response];
        return NO;
    }
    return YES;
}

- (void)failedWithMessage:(NSString *)message
{
    self.lastError = [NSError errorWithDomain:FTPErrorDomain
                                         code:502
                                     userInfo:[NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey]];
}

- (NSString *)temporaryUrl
{
    // Do not use NSURL. It will not allow you to read the file contents.
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"FTPKit.list"];
    //FKLogDebug(@"path: %@", path);
    return path;
}

- (NSDictionary *)entryByReencodingNameInEntry:(NSDictionary *)entry encoding:(NSStringEncoding)newEncoding
{
    // Convert to the preferred encoding. By default CF encodes the string
    // as MacRoman.
    NSString *newName = nil;
    NSString *name = [entry objectForKey:(id)kCFFTPResourceName];
    if (name != nil) {
        NSData *data = [name dataUsingEncoding:NSMacOSRomanStringEncoding];
        if (data != nil) {
            newName = [[NSString alloc] initWithData:data encoding:newEncoding];
        }
    }
    
    // If the above failed, just return the entry unmodified.  If it succeeded,
    // make a copy of the entry and replace the name with the new name that we
    // calculated.
    NSDictionary *result = nil;
    if (! newName) {
        result = (NSDictionary *)entry;
    } else {
        NSMutableDictionary *newEntry = [NSMutableDictionary dictionaryWithDictionary:entry];
        [newEntry setObject:newName forKey:(id)kCFFTPResourceName];
        result = newEntry;
    }
    return result;
}

- (NSArray *)parseListData:(NSData *)data handle:(FTPHandle *)handle showHiddentFiles:(BOOL)showHiddenFiles
{
    NSMutableArray *files = [NSMutableArray array];
    NSUInteger offset = 0;
    do {
        CFDictionaryRef thisEntry = NULL;
        CFIndex bytes = CFFTPCreateParsedResourceListing(NULL, &((const uint8_t *) data.bytes)[offset], data.length - offset, &thisEntry);
        if (bytes > 0) {
            if (thisEntry != NULL) {
                NSDictionary *entry = [self entryByReencodingNameInEntry:(__bridge NSDictionary *)thisEntry encoding:NSUTF8StringEncoding];
                FTPHandle *ftpHandle = [FTPHandle handleAtPath:handle.path attributes:entry];
				if (! [ftpHandle.name hasPrefix:@"."] || showHiddenFiles) {
					[files addObject:ftpHandle];
				}
            }
            offset += bytes;
        }
        
        if (thisEntry != NULL) {
            CFRelease(thisEntry);
        }
        
        if (bytes == 0) {
            break;
        } else if (bytes < 0) {
            [self failedWithMessage:NSLocalizedString(@"Failed to parse directory listing", @"")];
            return nil;
        }
    } while (YES);
    
    if (offset != data.length) {
        FKLogWarn(@"Some bytes not read!");
    }
    
    return files;
}

- (NSDate *)lastModifiedAtPath:(NSString *)remotePath
{
    netbuf *conn = [self connect];
    if (conn == NULL)
        return nil;
    const char *cPath = [[self urlEncode:remotePath] cStringUsingEncoding:NSUTF8StringEncoding];
    char dt[kFTPKitRequestBufferSize];
    // This is returning FALSE when attempting to create a new folder that exists... why?
    // MDTM does not work with folders. It is meant to be used only for types
    // of files that can be downloaded using the RETR command.
    int stat = FtpModDate(cPath, dt, kFTPKitRequestBufferSize, conn);
    NSString *response = [NSString stringWithCString:FtpLastResponse(conn) encoding:NSUTF8StringEncoding];
    FtpQuit(conn);
    if (stat == 0) {
        self.lastError = [NSError FTPKitErrorWithResponse:response];
        return nil;
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    // FTP spec: YYYYMMDDhhmmss
    // @note dt always contains a trailing newline char.
    formatter.dateFormat = @"yyyyMMddHHmmss\n";
    NSString *dateString = [NSString stringWithCString:dt encoding:NSUTF8StringEncoding];
    NSDate *date = [formatter dateFromString:dateString];
    return date;
}

- (void)lastModifiedAtPath:(NSString *)remotePath success:(void (^)(NSDate *))success failure:(void (^)(NSError *))failure
{
    dispatch_async(_queue, ^{
        NSDate *date = [self lastModifiedAtPath:remotePath];
        if (! _lastError && success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success(date);
            });
        } else if (_lastError && failure) {
            [self returnFailure:failure];
        }
    });
}

- (BOOL)directoryExistsAtPath:(NSString *)remotePath
{
    /**
     Test the directory by changing to the directory. If the process succeeds
     then the directory exists.
     
     The process is to get the current working directory and change _back_ to
     the previous current working directory. There is a possibility that the
     second changeDirectoryToPath: may fail! This is really the price we pay
     for this command as there is no other accurate way to determine this.
     
     Using listContentsAtPath:showHiddenFiles: will fail as it will return empty
     contents even if the directory doesn't exist! So long as the command
     _succeeds_ it will return an empty list.
     
    // Get the current working directory. We will change back to this directory
    // if necessary.
    NSString *cwd = [self printWorkingDirectory];
    // No need to continue. We already know the path exists by the fact that we
    // are currently _in_ the directory.
    if ([cwd isEqualToString:remotePath])
        return YES;
    // Test directory by changing to it.
    BOOL success = [self changeDirectoryToPath:remotePath];
    // Attempt to change back to the previous directory.
    if (success)
        [self changeDirectoryToPath:cwd];
    return success;
     */
    
    /**
     Currently the lib creates a new connection for every command issued.
     Therefore, it is unnecessary to change back to the original cwd.
     */
    netbuf *conn = [self connect];
    if (conn == NULL)
        return NO;
    const char *cPath = [remotePath cStringUsingEncoding:NSUTF8StringEncoding];
    int stat = FtpChdir(cPath, conn);
    FtpQuit(conn);
    if (stat == 0)
        return NO;
    return YES;
}

- (void)directoryExistsAtPath:(NSString *)remotePath success:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    dispatch_async(_queue, ^{
        BOOL exists = [self directoryExistsAtPath:remotePath];
        if (! _lastError && success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success(exists);
            });
        } else if (_lastError && failure) {
            [self returnFailure:failure];
        }
    });
}

- (BOOL)changeDirectoryToPath:(NSString *)remotePath
{
    netbuf *conn = [self connect];
    if (conn == NULL)
        return NO;
    const char *cPath = [remotePath cStringUsingEncoding:NSUTF8StringEncoding];
    int stat = FtpChdir(cPath, conn);
    NSString *response = [NSString stringWithCString:FtpLastResponse(conn) encoding:NSUTF8StringEncoding];
    FtpQuit(conn);
    if (stat == 0) {
        self.lastError = [NSError FTPKitErrorWithResponse:response];
        return NO;
    }
    return YES;
}

- (NSString *)printWorkingDirectory
{
    netbuf *conn = [self connect];
    if (conn == NULL)
        return nil;
    char cPath[kFTPKitTempBufferSize];
    int stat = FtpPwd(cPath, kFTPKitTempBufferSize, conn);
    NSString *response = [NSString stringWithCString:FtpLastResponse(conn) encoding:NSUTF8StringEncoding];
    FtpQuit(conn);
    if (stat == 0) {
        self.lastError = [NSError FTPKitErrorWithResponse:response];
        return nil;
    }
    return [NSString stringWithCString:cPath encoding:NSUTF8StringEncoding];
}

- (void)returnFailure:(void (^)(NSError *))failure
{
    NSError *error = [_lastError copy];
    dispatch_async(dispatch_get_main_queue(), ^{
        failure(error);
    });
}

@end
