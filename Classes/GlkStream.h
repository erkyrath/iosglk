/* GlkStream.h: Stream objc class (and subclasses)
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <Foundation/Foundation.h>
#include "glk.h"
#include "gi_dispa.h"

@class GlkLibrary;
@class GlkWindow;

typedef enum GlkStreamType_enum {
	strtype_None=0,
	strtype_File=1,
	strtype_Window=2,
	strtype_Memory=3
} GlkStreamType;

@interface GlkStream : NSObject {
	GlkLibrary *library;
	BOOL inlibrary;
	
	NSNumber *tag;
	gidispatch_rock_t disprock;

	GlkStreamType type; /* file, window, or memory stream */
	glui32 rock;
	BOOL unicode; /* one-byte or four-byte chars? Not meaningful for windows */

	glui32 readcount, writecount;
	BOOL readable, writable;
}

@property (nonatomic, retain) GlkLibrary *library;
@property (nonatomic, retain) NSNumber *tag;
@property (nonatomic, readonly) GlkStreamType type;
@property (nonatomic, readonly) glui32 rock;
@property (nonatomic, readonly) BOOL unicode;

- (id) initWithType:(GlkStreamType)strtype readable:(BOOL)isreadable writable:(BOOL)iswritable rock:(glui32)strrock;
- (void) streamDelete;
- (void) fillResult:(stream_result_t *)result;
- (void) setPosition:(glsi32)pos seekmode:(glui32)seekmode;
- (glui32) getPosition;
- (void) putChar:(unsigned char)ch;
- (void) putCString:(char *)s;
- (void) putBuffer:(char *)buf len:(glui32)len;
- (void) putUChar:(glui32)ch;
- (void) putUString:(glui32 *)us;
- (void) putUBuffer:(glui32 *)buf len:(glui32)len;
- (void) setStyle:(glui32)styl;

@end


@interface GlkStreamWindow : GlkStream {
	GlkWindow *win;
}

@property (nonatomic, retain) GlkWindow *win;

- (id) initWithWindow:(GlkWindow *)win;

@end

@interface GlkStreamMemory : GlkStream {
	/* The pointers needed for stream operation. We keep separate sets for the one-byte and four-byte cases. */
	unsigned char *buf;
	unsigned char *bufptr;
	unsigned char *bufend;
	unsigned char *bufeof;
	glui32 *ubuf;
	glui32 *ubufptr;
	glui32 *ubufend;
	glui32 *ubufeof;
	glui32 buflen;
}

- (id) initWithMode:(glui32)fmode rock:(glui32)rockval buf:(char *)buf len:(glui32)buflen;
- (id) initUniWithMode:(glui32)fmode rock:(glui32)rockval buf:(glui32 *)ubufval len:(glui32)ubuflenval;

@end

