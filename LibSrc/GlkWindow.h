/* GlkWindow.h: Window objc class (and subclasses)
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <Foundation/Foundation.h>
#include "glk.h"
#include "gi_dispa.h"

@class GlkLibrary;
@class GlkStream;
@class GlkWindowPair;
@class GlkWindowState;
@class StyleSet;
@class Geometry;

@interface GlkWindow : NSObject <NSSecureCoding> {
	BOOL inlibrary;

	void *line_buffer;
	gidispatch_rock_t inarrayrock;
	int line_buffer_length;
	BOOL char_request_uni;
	BOOL line_request_uni;
	BOOL pending_echo_line_input; // applies to current input; only meaningful for buffer windows
	
	/* These values are only used in a temporary GlkLibrary, while deserializing. */
	uint8_t *tempbufdata;
	NSUInteger tempbufdatalen;
	long tempbufkey;
}

@property (nonatomic, weak) GlkLibrary *library;
@property (nonatomic, strong) NSNumber *tag;
@property (nonatomic) gidispatch_rock_t disprock;
@property (nonatomic, readonly) glui32 type;
@property (nonatomic, readonly) glui32 rock;
@property (nonatomic, weak) GlkWindowPair *parent;
@property (nonatomic, strong) NSNumber *parenttag;
@property (nonatomic, weak) NSString *line_request_initial;
@property (nonatomic, readonly) int input_request_id;
@property (nonatomic, readonly) BOOL char_request;
@property (nonatomic, readonly) BOOL line_request;
@property (nonatomic) BOOL echo_line_input; // applies to future inputs
@property (nonatomic) glui32 style;
@property (nonatomic, strong) GlkStream *stream;
@property (nonatomic, strong) NSNumber *streamtag;
@property (nonatomic, strong) GlkStream *echostream;
@property (nonatomic, strong) NSNumber *echostreamtag;
@property (nonatomic, strong) StyleSet *styleset; // not serialized
@property (nonatomic) CGRect bbox;

+ (GlkWindow *) windowWithType:(glui32)type rock:(glui32)rock;

- (instancetype) initWithType:(glui32)type rock:(glui32)rock;
- (void) updateRegisterArray;
- (void) windowCloseRecurse:(BOOL)recurse;
- (void) windowRearrange:(CGRect)box;
- (void) getWidth:(glui32 *)widthref height:(glui32 *)heightref;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL supportsInput;
- (void) dirtyAllData;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) GlkWindowState *cloneState;

+ (void) unEchoStream:(strid_t)str;
- (void) putBuffer:(char *)buf len:(glui32)len;
- (void) putUBuffer:(glui32 *)buf len:(glui32)len;
- (void) clearWindow;

- (void) beginCharInput:(BOOL)unicode;
- (BOOL) acceptCharInput:(glui32 *)chref;
- (void) cancelCharInput;
- (void) beginLineInput:(void *)buf unicode:(BOOL)unicode maxlen:(glui32)maxlen initlen:(glui32)initlen;
- (int) acceptLineInput:(NSString *)str;
- (void) cancelLineInput:(event_t *)event;

@end


@interface GlkWindowBuffer : GlkWindow

/* incremented whenever the buffer is cleared */
@property (nonatomic) int clearcount;
@property (nonatomic, strong) NSMutableAttributedString *attrstring;
@property (nonatomic, strong) NSMutableAttributedString *savedattrstring;
- (void) putString:(NSString *)str;

@end


@interface GlkWindowGrid : GlkWindow {
	int width, height;
	int curx, cury; /* the window cursor position */
}

@property (nonatomic, readonly) int width;
@property (nonatomic, readonly) int height;
@property (nonatomic, readonly) int curx;
@property (nonatomic, readonly) int cury;
@property (nonatomic, strong) NSMutableAttributedString *attrstring;

- (void) moveCursorToX:(glui32)xpos Y:(glui32)ypos;
- (void) putUChar:(glui32)ch;

@end


@interface GlkWindowPair : GlkWindow

@property (nonatomic, strong) Geometry *geometry;
@property (nonatomic) BOOL keydamage; // only used within glk_window_close().
@property (nonatomic, strong) GlkWindow *child1;
@property (nonatomic, strong) GlkWindow *child2;

- (instancetype) initWithMethod:(glui32)method keywin:(GlkWindow *)keywin size:(glui32)size;

@end


