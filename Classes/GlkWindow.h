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
@class StyleSet;

@interface GlkWindow : NSObject {
	GlkLibrary *library;
	BOOL inlibrary;
	
	NSNumber *tag;
	gidispatch_rock_t disprock;
	glui32 type;
	glui32 rock;
	
	GlkWindowPair *parent;
	BOOL char_request;
	BOOL line_request;
	BOOL char_request_uni;
	BOOL line_request_uni;
	BOOL echo_line_input;
	glui32 style;
	
	GlkStream *stream;
	GlkStream *echostream;
	
	StyleSet *styleset;
	CGRect bbox;
}

@property (nonatomic, retain) GlkLibrary *library;
@property (nonatomic, retain) NSNumber *tag;
@property (nonatomic) glui32 type;
@property (nonatomic) glui32 rock;
@property (nonatomic, retain) GlkWindowPair *parent;
@property (nonatomic) BOOL char_request;
@property (nonatomic) BOOL line_request;
@property (nonatomic) glui32 style;
@property (nonatomic, retain) GlkStream *stream;
@property (nonatomic, retain) GlkStream *echostream;
@property (nonatomic, retain) StyleSet *styleset;
@property (nonatomic) CGRect bbox;

+ (void) initialize;
+ (GlkWindow *) windowWithType:(glui32)type rock:(glui32)rock;

- (id) initWithType:(glui32)type rock:(glui32)rock;
- (void) windowCloseRecurse:(BOOL)recurse;
- (void) windowRearrange:(CGRect)box;
- (void) getWidth:(glui32 *)widthref height:(glui32 *)heightref;

+ (void) unEchoStream:(strid_t)str;
- (void) putBuffer:(char *)buf len:(glui32)len;
- (void) putUBuffer:(glui32 *)buf len:(glui32)len;
- (void) clearWindow;

@end


@interface GlkWindowBuffer : GlkWindow {
	NSMutableArray *updatetext; /* array of GlkStyledLine */
}

@property (nonatomic, retain) NSMutableArray *updatetext;

- (void) putString:(NSString *)str;

@end


@interface GlkWindowGrid : GlkWindow {
	int width, height;
	NSMutableArray *lines; /* array of GlkGridLine */
	
	int curx, cury; /* the window cursor position */
}

@property (nonatomic, retain) NSMutableArray *lines;
@property (nonatomic) int width;
@property (nonatomic) int height;

- (void) moveCursorToX:(glui32)xpos Y:(glui32)ypos;
- (void) putUChar:(glui32)ch;

@end


@interface GlkWindowPair : GlkWindow {
	glui32 dir;
	glui32 division;
	BOOL hasborder;
	GlkWindow *key;
	glui32 size;
	BOOL keydamage;
	BOOL vertical;
	BOOL backward;
	
	GlkWindow *child1;
	GlkWindow *child2;
	
	CGFloat split;
	CGFloat splitwid;
}

@property (nonatomic) glui32 dir;
@property (nonatomic) glui32 division;
@property (nonatomic) BOOL hasborder;
@property (nonatomic, retain) GlkWindow *key;
@property (nonatomic) glui32 size;
@property (nonatomic) BOOL keydamage;
@property (nonatomic) BOOL vertical;
@property (nonatomic) BOOL backward;
@property (nonatomic, retain) GlkWindow *child1;
@property (nonatomic, retain) GlkWindow *child2;

- (id) initWithMethod:(glui32)method keywin:(GlkWindow *)keywin size:(glui32)size;

@end


