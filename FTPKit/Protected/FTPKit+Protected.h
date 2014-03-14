#ifndef FTPKit_FTPKit_Protected_h
#define FTPKit_FTPKit_Protected_h

#define kFTPKitRequestBufferSize 32768
#define kFTPKitTempBufferSize 1024

//#define FKLog(level, msg) NSLog(@"FTPKit: (%@) %@", level, msg)
#define FKLogDebug(frmt, ...) NSLog(@"FTPKit: (Debug) %@", [NSString stringWithFormat:frmt, ##__VA_ARGS__])
#define FKLogInfo(frmt, ...) NSLog(@"FTPKit: (Info) %@", [NSString stringWithFormat:frmt, ##__VA_ARGS__])
#define FKLogWarn(frmt, ...) NSLog(@"FTPKit: (Warn) %@", [NSString stringWithFormat:frmt, ##__VA_ARGS__])
#define FKLogError(frmt, ...) NSLog(@"FTPKit: (Error) %@", [NSString stringWithFormat:frmt, ##__VA_ARGS__])

#endif
