/* GlkFileRef.h: File-reference objc class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <Foundation/Foundation.h>
#include "glk.h"
#include "gi_dispa.h"

@class GlkLibrary;


@interface GlkFileRef : NSObject {
	GlkLibrary *library;
	BOOL inlibrary;
	
	NSNumber *tag;
	gidispatch_rock_t disprock;

	glui32 rock;
	
	glui32 filetype;
	BOOL textmode;
}

@property (nonatomic, retain) GlkLibrary *library;
@property (nonatomic, retain) NSNumber *tag;
@property (nonatomic, readonly) glui32 filetype;
@property (nonatomic, readonly) glui32 rock;
@property (nonatomic, readonly) BOOL textmode;

- (id) initWithType:(glui32)usage rock:(glui32)frefrock;
- (void) filerefDelete;

@end
