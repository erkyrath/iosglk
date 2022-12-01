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

@interface GlkWindowState : NSObject

@property (nonatomic, weak) GlkLibraryState *library; // weak parent link
@property (nonatomic, strong) NSNumber *tag;
@property (nonatomic) glui32 type;
@property (nonatomic) glui32 rock;
@property (nonatomic, strong) StyleSet *styleset;
@property (nonatomic) CGRect bbox;
@property (nonatomic) int input_request_id;
@property (nonatomic) BOOL char_request;
@property (nonatomic) BOOL line_request;
@property (nonatomic, strong) NSString *line_request_initial;

+ (GlkWindowState *) windowStateWithType:(glui32)type rock:(glui32)rock;

@end


@interface GlkWindowBufferState : GlkWindowState

@property (nonatomic) int clearcount; /* incremented whenever the buffer is cleared */
@property (nonatomic, strong) NSAttributedString *attrstring;

@end

@interface GlkWindowGridState : GlkWindowState

@property (nonatomic) int width;
@property (nonatomic) int height;
@property (nonatomic) int curx; /* the window cursor position */
@property (nonatomic) int cury;
@property (nonatomic, strong) NSAttributedString *attrstring;

@end

@interface GlkWindowPairState : GlkWindowState

@property (nonatomic, strong) Geometry *geometry;

@end

