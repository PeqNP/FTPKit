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
- (void)start;
- (void)cancel;

// Protected methods.

- (void)stop;
- (void)didUpdateProgress:(float)progress;
- (void)didUpdateStatus:(NSString*)status;
- (void)didFailWithError:(NSError *)error;
- (void)didFailWithMessage:(NSString *)message;

@end