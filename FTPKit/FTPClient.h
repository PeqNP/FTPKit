#import "FTPHandle.h"
#import "FTPCredentials.h"
#import "FTPRequest.h"

@class FTPClient;

@protocol FTPClientDelegate <NSObject>

@optional

- (void)client:(FTPClient *)client request:(FTPRequest *)request didChmodFile:(NSString *)path toMode:(int)mode;
- (void)client:(FTPClient *)client request:(FTPRequest *)request didDeleteFile:(NSString *)path;
- (void)client:(FTPClient *)client request:(FTPRequest *)request didDownloadFile:(NSString *)remotePath to:(NSString *)localPath;
- (void)client:(FTPClient *)client request:(FTPRequest *)request didListContents:(NSArray *)contents;
- (void)client:(FTPClient *)client request:(FTPRequest *)request didMakeDirectory:(NSString *)path;
- (void)client:(FTPClient *)client request:(FTPRequest *)request didUploadFile:(NSString *)localPath to:(NSString *)remotePath;

- (void)client:(FTPClient *)client request:(FTPRequest *)request didUpdateStatus:(NSString *)status;
- (void)client:(FTPClient *)client request:(FTPRequest *)request didUpdateProgress:(float)progress;
- (void)client:(FTPClient *)client request:(FTPRequest *)request didFailWithError:(NSError *)error;
- (void)client:(FTPClient *)client requestDidCancel:(FTPRequest *)request;

@end

@interface FTPClient : NSObject <FTPRequestDelegate>

@property (nonatomic, weak) id<FTPClientDelegate> delegate;
@property (nonatomic, readonly) FTPCredentials* credentials;
@property (nonatomic, readonly) NSString *currentDirectory;

/**
 Factory method to create FTPClient instance.
 
 @param FTPLocation The location's credentials
 @return FTPClient
 */
+ (FTPClient *)clientWithCredentials:(FTPCredentials *)credentials;

/**
 Factory method to create FTPClient instance.
 
 @param host Server host to connect to
 @param port Server port.
 @param username Username to login as.
 @param password Password of user.
 @return FTPClient
 */
+ (FTPClient *)clientWithHost:(NSString *)host port:(int)port username:(NSString *)username password:(NSString* )password;

/**
 Create an instance of FTPClient.
 
 @param FTPLocation The location's credentials
 @return FTPClient
 */
- (instancetype)initWithCredentials:(FTPCredentials *)credentials;

/**
 Create an instance of FTPClient.
 
 @param host Server host to connect to.
 @param port Server port.
 @param username Username to login as.
 @param password Password of user.
 @return FTPClient
 */
- (instancetype)initWithHost:(NSString *)host port:(int)port username:(NSString *)username password:(NSString* )password;

/**
 List directory contents at path.
 
 @param showHiddenItems Show hidden items in directory.
 @return FTPRequest The request instance.
 */
- (FTPRequest *)listContentsAtPath:(NSString *)path showHiddenFiles:(BOOL)showHiddenFiles;

/**
 List handle's directory contents.
 
 @param showHiddenItems Show hidden items in directory.
 @return FTPRequest The request instance.
 */
- (FTPRequest *)listContentsAtHandle:(FTPHandle *)handle showHiddenFiles:(BOOL)showHiddenFiles;

/**
 Download remote file path to local path.
 
 @param fileName Full path of remote file to download.
 @param localPath Local path to download file to.
 @return FTPRequest The request instance.
 */
- (FTPRequest *)downloadFile:(NSString *)remotePath to:(NSString *)localPath;

/**
 Download handle at specific location.
 
 @param handle Handle to download. Handles are produced by listDirectory* and friends.
 @param localPath Local path to download file to.
 @returns FTPRequest The request instance.
 */
- (FTPRequest *)downloadHandle:(FTPHandle *)handle to:(NSString *)localPath;

/**
 Upload file to specific directory on remote server.
 
 @param localPath Path of local file to upload.
 @return FTPRequest The request instance.
 */
- (FTPRequest *)uploadFile:(NSString *)localPath to:(NSString *)remotePath;

/**
 Create directory at the specified path on the remote server.
 
 @param directoryName Name of directory to create on remote server.
 @param remotePath Path to remote directory where file should be created.
 @return FTPRequest The request instance.
 */
- (FTPRequest *)createDirectory:(NSString *)directoryName atPath:(NSString *)remotePath;

/**
 Create remote directory within the handle's location.
 
 @param directoryName Name of directory to create on remote server.
 @param remotePath Path to remote directory where file should be created.
 @return FTPRequest The request instance.
 */
- (FTPRequest *)createDirectory:(NSString *)directoryName atHandle:(FTPHandle *)handle;

/**
 Delete a file or folder at a specified remote path.
 
 @param remotePath The path to the remote resource to delete.
 @return FTPRequest The request instance.
 */
- (FTPRequest *)deleteFile:(NSString *)remotePath;

/**
 Delete a remote handle from the server.
 
 @param handle The remote handle to delete.
 @return FTPRequest The request instance.
 */
- (FTPRequest *)deleteHandle:(FTPHandle *)handle;

/**
 Change file mode of a remote file or folder.
 
 @param remotePath Full path to remote resource.
 @param mode File mode to change to.
 @return FTPRequest The request instance.
 */
- (FTPRequest *)chmodFile:(NSString *)remotePath toMode:(int)mode;

/**
 Change file mode of a remote handle.
 
 @param handle The remote handle to change mode on.
 @param mode File mode to change to.
 @return FTPRequest The request instance.
 */
- (FTPRequest *)chmodHandle:(FTPHandle *)handle toMode:(int)mode;

@end