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
@property (nonatomic) gidispatch_rock_t disprock;
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
- (glsi32) getChar:(BOOL)unicode;
- (glui32) getBuffer:(void *)buf buflen:(glui32)buflen unicode:(BOOL)unicode;
- (glui32) getLine:(void *)buf buflen:(glui32)buflen unicode:(BOOL)unicode;

@end


@interface GlkStreamWindow : GlkStream {
	GlkWindow *win;
	NSNumber *wintag;
}

@property (nonatomic, retain) GlkWindow *win;
@property (nonatomic, retain) NSNumber *wintag;

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
	gidispatch_rock_t arrayrock;
}

- (id) initWithMode:(glui32)fmode rock:(glui32)rockval buf:(char *)buf len:(glui32)buflen;
- (id) initUniWithMode:(glui32)fmode rock:(glui32)rockval buf:(glui32 *)ubufval len:(glui32)ubuflenval;

@end

@interface GlkStreamFile : GlkStream {
	NSFileHandle *handle;
	NSString *pathname; // only needed for serialization
	glui32 fmode;
	BOOL textmode;
	
	int maxbuffersize; // how much data to buffer at a time (ideally)
	NSData *readbuffer; // if !writable
	NSMutableData *writebuffer; // if writable
	unsigned long long bufferpos; // position within the file where the buffer begins
	// the following are all relative to bufferpos:
	int buffermark; // offset within the buffer where the mark sits
	int buffertruepos; // offset within the buffer where the filehandle's mark sits
	int bufferdirtystart; // buffersize if nothing dirty
	int bufferdirtyend; // 0 if nothing dirty
}

@property (nonatomic, retain) NSFileHandle *handle;
@property (nonatomic, retain) NSString *pathname;
@property (nonatomic, retain) NSData *readbuffer;
@property (nonatomic, retain) NSMutableData *writebuffer;

- (id) initWithMode:(glui32)fmode rock:(glui32)rockval unicode:(BOOL)unicode fileref:(GlkFileRef *)fref;
- (id) initWithMode:(glui32)fmode rock:(glui32)rockval unicode:(BOOL)isunicode textmode:(BOOL)istextmode dirname:(NSString *)dirname pathname:(NSString *)pathname;

- (void) flush;
- (int) readByte;
- (glui32) readBytes:(void **)byteref len:(glui32)len;
- (void) writeByte:(char)ch;
- (void) writeBytes:(void *)bytes len:(glui32)len;

@end

