/* GlkFileRef.h: File-reference objc class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <Foundation/Foundation.h>
#include "glk.h"
#include "gi_dispa.h"

@class GlkLibrary;


@interface GlkFileRef : NSObject <NSSecureCoding> {
	GlkLibrary *library;
	BOOL inlibrary;
	
	NSNumber *tag;
	gidispatch_rock_t disprock;

	glui32 rock;
	
	NSString *filename;
	NSString *basedir;
	NSString *dirname; // basedir + subDirOfBase
	NSString *pathname; // dirname + filename
	glui32 filetype;
	BOOL textmode;
}

@property (nonatomic, strong) GlkLibrary *library;
@property (nonatomic, strong) NSNumber *tag;
@property (nonatomic) gidispatch_rock_t disprock;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSString *basedir;
@property (nonatomic, strong) NSString *dirname;
@property (nonatomic, strong) NSString *pathname;
@property (nonatomic, readonly) glui32 filetype;
@property (nonatomic, readonly) glui32 rock;
@property (nonatomic, readonly) BOOL textmode;

+ (NSString *) documentsDirectory;
+ (NSString *) relativizePath:(NSString *)path;
+ (NSString *) unrelativizePath:(NSString *)path;
+ (NSString *) subDirOfBase:(NSString *)basedir forUsage:(glui32)usage gameid:(NSString *)gameid;

- (id) initWithBase:(NSString *)basedir filename:(NSString *)filename type:(glui32)usage rock:(glui32)frefrock;
- (void) filerefDelete;

@end
