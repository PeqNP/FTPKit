
#import "ftplib.h"

#import "FTPCredentials.h"

@class FTPRequest;

@protocol FTPRequestDelegate <NSObject>

@optional

/*
 * Private delegate methods. Each method is called by a specific request type.
 * Such that didDeleteFile: is used by the FTPDeleteFileRequest, didMakeDirectory:
 * by the FTPDeleteFileRequest, etc.
 */

- (void)request:(FTPRequest *)request didChmodPath:(NSString *)path;
- (void)request:(FTPRequest *)request didDeletePath:(NSString *)path;
- (void)request:(FTPRequest *)request didDownloadFile:(NSString *)remotePath to:(NSString *)localPath;
- (void)request:(FTPRequest *)request didList:(NSArray *)handles;
- (void)request:(FTPRequest *)request didMakeDirectory:(NSString *)path;
- (void)request:(FTPRequest *)request didUploadFile:(NSString *)localPath to:(NSString *)remotePath;
- (void)request:(FTPRequest *)request didRenamePath:(NSString *)sourcePath to:(NSString *)destPath;

/* These methods are used by almost every request type. */

- (void)request:(FTPRequest *)request didUpdateStatus:(NSString *)status;
- (void)request:(FTPRequest *)request didUpdateProgress:(float)progress;
- (void)request:(FTPRequest *)request didFailWithError:(NSError *)error;
- (void)requestDidCancel:(FTPRequest *)request;

@end

@interface FTPRequest : NSObject

@property (nonatomic, weak) id<FTPRequestDelegate> delegate;
@property (nonatomic, readonly) FTPCredentials *credentials;

// Public methods.

- (instancetype)initWithCredentials:(FTPCredentials *)credentials;

/**
 Start the request.
 */
- (void)start;

/**
 Cancel the request.
 */
- (void)cancel;

// Protected methods.

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
 Stop all communication with server and release any connection resources used
 for the request.
 */
- (void)stop;

/**
 Convenience methods that call delegate callbacks for respective events. 
 */
- (void)didUpdateProgress:(float)progress;
- (void)didUpdateStatus:(NSString*)status;
- (void)didFailWithError:(NSError *)error;
- (void)didFailWithMessage:(NSString *)message;

@end