
#import "ftplib.h"

#import "FTPCredentials.h"

@interface FTPRequest : NSObject

@property (nonatomic, readonly) FTPCredentials *credentials;

@property (nonatomic, readonly) NSError *error;

// Public methods.

- (instancetype)initWithCredentials:(FTPCredentials *)credentials;

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