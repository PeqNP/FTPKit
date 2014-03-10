#import "FTPClient.h"
#import "FTPListRequest.h"
#import "FTPGetRequest.h"
#import "FTPPutRequest.h"
#import "FTPMakeDirectoryRequest.h"
#import "FTPDeleteFileRequest.h"
#import "FTPChmodRequest.h"

@interface FTPClient ()
@property (nonatomic, strong) FTPCredentials* credentials;
@property (nonatomic, strong) NSMutableArray *requests;
@end

@implementation FTPClient

@synthesize delegate;
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
	}
	return self;
}

- (instancetype)initWithHost:(NSString *)host port:(int)port username:(NSString *)username password:(NSString *)password
{
    FTPCredentials *creds = [FTPCredentials credentialsWithHost:host port:port username:username password:password];
	return [self initWithCredentials:creds];
}

- (FTPRequest *)listContentsAtPath:(NSString *)path showHiddenFiles:(BOOL)showHiddenFiles
{
    FTPHandle *hdl = [FTPHandle handleAtPath:path];
    return [self listContentsAtHandle:hdl showHiddenFiles:showHiddenFiles];
}

- (FTPRequest *)listContentsAtHandle:(FTPHandle *)handle showHiddenFiles:(BOOL)showHiddenFiles
{
    FTPListRequest *request = [FTPListRequest requestWithCredentials:credentials handle:handle];
    request.showHiddenItems = showHiddenFiles;
	request.delegate = self;
	[requests addObject:request];
	[request start];
    return request;
}

- (FTPRequest *)downloadFile:(NSString *)remotePath to:(NSString *)localPath
{
    return [self downloadHandle:[FTPHandle handleAtPath:remotePath] to:localPath];
}

- (FTPRequest *)downloadHandle:(FTPHandle *)handle to:(NSString *)localPath
{
    FTPGetRequest *request = [FTPGetRequest requestWithCredentials:credentials
                                                    downloadHandle:handle
                                                                to:localPath];
	request.delegate = self;
	[requests addObject:request];
	[request start];
    return request;
}

- (FTPRequest *)uploadFile:(NSString *)localPath to:(NSString *)remotePath
{
	FTPPutRequest* request = [FTPPutRequest requestWithCredentials:credentials uploadFile:localPath to:remotePath];
	request.delegate = self;
	[requests addObject:request];
	[request start];
    return request;
}

- (FTPRequest *)createDirectoryAtPath:(NSString *)remotePath
{
    return [self createDirectoryAtHandle:[FTPHandle handleAtPath:remotePath]];
}

- (FTPRequest *)createDirectoryAtHandle:(FTPHandle *)handle
{
	FTPMakeDirectoryRequest* request = [FTPMakeDirectoryRequest requestWithCredentials:credentials handle:handle];
	request.delegate = self;
	[requests addObject:request];
	[request start];
    return request;
}

- (FTPRequest *)deleteFile:(NSString *)remotePath
{
    return [self deleteHandle:[FTPHandle handleAtPath:remotePath]];
}

- (FTPRequest *)deleteHandle:(FTPHandle *)handle
{
	FTPDeleteFileRequest* request = [FTPDeleteFileRequest requestWithCredentials:credentials handle:handle];
	request.delegate = self;
	[requests addObject:request];
	[request start];
    return request;
}

- (FTPRequest *)chmodFile:(NSString *)remotePath toMode:(int)mode
{
    return [self chmodHandle:[FTPHandle handleAtPath:remotePath] toMode:mode];
}

- (FTPRequest *)chmodHandle:(FTPHandle *)handle toMode:(int)mode
{
    FTPChmodRequest *request = [FTPChmodRequest requestWithCredentials:credentials handle:handle];
    request.mode = mode;
    request.delegate = self;
    [requests addObject:request];
    [request start];
    return request;
}

// FTPRequestDelegate

- (void)request:(FTPRequest *)request didList:(NSArray *)handles
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(client:request:didListContents:)])
        {
            [self.delegate client:self request:request didListContents:handles];
        }
        [requests removeObject:request];
    });
}

- (void)request:(FTPRequest *)request didDownloadFile:(NSString *)remotePath to:(NSString *)localPath
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(client:request:didDownloadFile:to:)])
        {
            [self.delegate client:self request:request didDownloadFile:remotePath to:localPath];
        }
        [requests removeObject:request];
    });
}

- (void)request:(FTPRequest*)request didUploadFile:(NSString *)localPath to:(NSString *)remotePath
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(client:request:didUploadFile:to:)])
        {
            [self.delegate client:self request:request didUploadFile:localPath to:remotePath];
        }
        [requests removeObject:request];
    });
}

- (void)request:(FTPRequest *)request didMakeDirectory:(NSString *)path
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(client:request:didMakeDirectory:)])
        {
            [self.delegate client:self request:request didMakeDirectory:path];
        }
        [requests removeObject:request];
    });
}

- (void)request:(FTPRequest *)request didDeleteFile:(NSString *)path
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(client:request:didDeleteFile:)])
        {
            [self.delegate client:self request:request didDeleteFile:path];
        }
        [requests removeObject:request];
    });
}

- (void)request:(FTPRequest *)request didChmodFile:(NSString *)path
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(client:request:didChmodFile:toMode:)])
        {
            FTPChmodRequest *req = (FTPChmodRequest *)request;
            [self.delegate client:self request:request didChmodFile:path toMode:req.mode];
        }
        [requests removeObject:request];
    });
}

- (void)request:(FTPRequest *)request didUpdateStatus:(NSString *)status
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(client:request:didUpdateStatus:)])
        {
            [self.delegate client:self request:request didUpdateStatus:status];
        }
    });
}

- (void)request:(FTPRequest *)request didUpdateProgress:(float)progress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(client:request:didUpdateProgress:)])
        {
            [self.delegate client:self request:request didUpdateProgress:progress];
        }
    });
}

- (void)request:(FTPRequest *)request didFailWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(client:request:didFailWithError:)])
        {
            [self.delegate client:self request:request didFailWithError:error];
        }
        [requests removeObject:request];
    });
}

- (void)requestDidCancel:(FTPRequest *)request
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(client:requestDidCancel:)])
        {
            [self.delegate client:self requestDidCancel:request];
        }
        [requests removeObject:request];
    });
}

@end
