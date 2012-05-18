/* GlkWindowState.h: A class (and subclasses) that encapsulates all the UI-important state of a window
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import <Foundation/Foundation.h>
#include "glk.h"

@class GlkLibraryState;
@class StyleSet;
@class Geometry;

@interface GlkWindowState : NSObject {
	GlkLibraryState *library; // weak parent link (unretained)
	
	NSNumber *tag;
	glui32 type;
	glui32 rock;
	
	StyleSet *styleset;
	CGRect bbox;
	int input_request_id;
	BOOL char_request;
	BOOL line_request;
	NSString *line_request_initial;
}

@property (nonatomic, assign) GlkLibraryState *library; // unretained
@property (nonatomic, retain) NSNumber *tag;
@property (nonatomic) glui32 type;
@property (nonatomic) glui32 rock;
@property (nonatomic, retain) StyleSet *styleset;
@property (nonatomic) CGRect bbox;
@property (nonatomic) int input_request_id;
@property (nonatomic) BOOL char_request;
@property (nonatomic) BOOL line_request;
@property (nonatomic, retain) NSString *line_request_initial;

+ (GlkWindowState *) windowStateWithType:(glui32)type rock:(glui32)rock;

@end


@interface GlkWindowBufferState : GlkWindowState {
	int clearcount; /* incremented whenever the buffer is cleared */
	int linesdirtyfrom; /* index of first new (or changed) line */
	int linesdirtyto; /* the index of the last line, plus one (or zero if there are no lines */
	NSArray *lines; /* array of GlkStyledLine (indexes do not necessarily start at zero!) */
}

@property (nonatomic) int clearcount;
@property (nonatomic) int linesdirtyfrom;
@property (nonatomic) int linesdirtyto;
@property (nonatomic, retain) NSArray *lines;

@end

@interface GlkWindowGridState : GlkWindowState {
	int width, height;
	NSArray *lines; /* array of GlkStyledLine (may be sparse or empty) */
	
	int curx, cury; /* the window cursor position */
}

@property (nonatomic, retain) NSArray *lines;
@property (nonatomic) int width;
@property (nonatomic) int height;
@property (nonatomic) int curx;
@property (nonatomic) int cury;

@end

@interface GlkWindowPairState : GlkWindowState {
	Geometry *geometry;
}

@property (nonatomic, retain) Geometry *geometry;

@end

