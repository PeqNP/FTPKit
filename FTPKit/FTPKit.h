#import "ftplib.h"

#import <FTPKit/FTPClient.h>
#import <FTPKit/FTPCredentials.h>
#import <FTPKit/FTPHandle.h>
#import <FTPKit/FTPRequest.h>

#ifndef __CFNETWORK__
#pragma message("CFNetwork framework not found in project, or not included in precompiled header. Be sure to include all required frameworks.")
#endif