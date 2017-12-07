typedef enum {
	FTPHandleTypeUnknown = 0,
	FTPHandleTypeFIFO = 1,
	FTPHandleTypeCharacterDevice = 2,
	FTPHandleTypeDirectory = 4,
	FTPHandleTypeBLL = 6,
	FTPHandleTypeFile = 8,
	FTPHandleTypeLink = 10,
	FTPHandleTypeSocket = 12,
	FTPHandleTypeWHT = 14
} FTPHandleType;

@interface FTPHandle : NSObject

@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) NSDate *modified;
@property (nonatomic, readonly) NSString *group;
@property (nonatomic, readonly) NSString *owner;
@property (nonatomic, readonly) NSString *link;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) unsigned long long size;
@property (nonatomic, readonly) FTPHandleType type;
@property (nonatomic, readonly) int mode;

/**
 Factory: Create handle from CFFTPResource* dictionary attributes.
 
 @param path Parent directory of remote resource.
 @param attributes A dictionary containing CFFTPResource* attributes.
 @return instancetype
 */
+ (instancetype)handleAtPath:(NSString *)path attributes:(NSDictionary *)attributes;

/**
 Factory: Create a handle with the full path of a resource w/ no attributes.
 
 @param path Full path of remote resource.
 @return instancetype
 */
+ (instancetype)handleAtPath:(NSString *)path type:(FTPHandleType)type;

/**
 Create handle from CFFTPResource* dictionary attributes.
 
 @param path Parent directory to remote resource.
 @param attributes A dictionary containing CFFTPResource* attributes.
 @return instancetype
 */
- (instancetype)initWithPath:(NSString *)path attributes:(NSDictionary *)attributes;

/**
 Create a handle with the full path of a resource w/ no attributes.
 
 @param path Full path of remote resource.
 @return instancetype
 */
- (instancetype)initWithPath:(NSString *)path type:(FTPHandleType)type;

/**
 If mode set, returns string representation of file permissions.
 
 @return string representation of permissions.
 */
- (NSString *)permissions;

@end
