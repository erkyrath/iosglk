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

@property (nonatomic, strong) GlkLibrary *library;
@property (nonatomic, strong) NSNumber *tag;
@property (nonatomic) gidispatch_rock_t disprock;
@property (nonatomic, readonly) GlkStreamType type;
@property (nonatomic, readonly) glui32 rock;
@property (nonatomic, readonly) BOOL unicode;
@property (nonatomic, readonly) BOOL readable;
@property (nonatomic, readonly) BOOL writable;

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

@property (nonatomic, strong) GlkWindow *win;
@property (nonatomic, strong) NSNumber *wintag;

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
	
	/* These values are only used in a temporary GlkLibrary, while deserializing. */
	uint8_t *tempbufdata;
	NSUInteger tempbufdatalen;
	long tempbufkey;
	glui32 tempbufptr, tempbufend, tempbufeof;
}

@property (nonatomic, readonly) glui32 buflen;
@property (nonatomic, readonly) unsigned char *buf;
@property (nonatomic, readonly) glui32 *ubuf;

- (id) initWithMode:(glui32)fmode rock:(glui32)rockval buf:(char *)buf len:(glui32)buflen;
- (id) initUniWithMode:(glui32)fmode rock:(glui32)rockval buf:(glui32 *)ubufval len:(glui32)ubuflenval;
- (void) updateRegisterArray;

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
	
	unsigned long long offsetinfile; // (in bytes) only used during deserialization; zero normally
}

@property (nonatomic, strong) NSFileHandle *handle;
@property (nonatomic, strong) NSString *pathname;
@property (nonatomic, strong) NSData *readbuffer;
@property (nonatomic, strong) NSMutableData *writebuffer;
@property (nonatomic) unsigned long long offsetinfile;

- (id) initWithMode:(glui32)fmode rock:(glui32)rockval unicode:(BOOL)unicode fileref:(GlkFileRef *)fref;
- (id) initWithMode:(glui32)fmode rock:(glui32)rockval unicode:(BOOL)isunicode textmode:(BOOL)istextmode dirname:(NSString *)dirname pathname:(NSString *)pathname;

- (void) flush;
- (BOOL) reopenInternal;
- (int) readByte;
- (glui32) readBytes:(void **)byteref len:(glui32)len;
- (void) writeByte:(char)ch;
- (void) writeBytes:(void *)bytes len:(glui32)len;

@end

