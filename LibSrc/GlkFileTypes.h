/* GlkFileTypes.h: Miscellaneous file-related objc classes
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <Foundation/Foundation.h>
#include "glk.h"

@interface GlkFileRefPrompt : NSObject {
	glui32 usage;
	glui32 fmode;
	NSString *dirname;
	NSString *filename;
	NSString *pathname;
}

- (id) initWithUsage:(glui32)usage fmode:(glui32)fmode dirname:(NSString *)dirname;

@property (nonatomic) glui32 usage;
@property (nonatomic) glui32 fmode;
@property (nonatomic, retain) NSString *dirname;
@property (nonatomic, retain) NSString *filename;
@property (nonatomic, retain) NSString *pathname;

@end


@interface GlkFileThumb : NSObject {
	NSString *label;
	NSString *filename;
	NSString *pathname;
	glui32 usage;
	NSDate *modtime;
	BOOL isfake;
}

@property (nonatomic, retain) NSString *label;
@property (nonatomic, retain) NSString *filename;
@property (nonatomic, retain) NSString *pathname;
@property (nonatomic) glui32 usage;
@property (nonatomic, retain) NSDate *modtime;
@property (nonatomic) BOOL isfake;

+ (NSString *) labelForFileUsage:(glui32)usage localize:(NSString *)key;

- (NSComparisonResult) compareModTime:(GlkFileThumb *)other;

@end

