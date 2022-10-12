/* GlkWindowView.h: Base class for a Glk window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>
#include "glk.h"

typedef enum SelDragMode_enum {
	SelDrag_none = 0,
	SelDrag_paragraph = 1,
	SelDrag_topedge = 2,
	SelDrag_bottomedge = 3,
} SelDragMode;

@class GlkWindowState;
@class GlkFrameView;
@class CmdTextField;
@class StyleSet;

@interface GlkWindowView : UIView <UITextFieldDelegate> {
	GlkWindowState *winstate; /* a clone of the most recent window state */
	StyleSet *styleset; /* the same as the window's, unless the player is changing things */
	
	UIEdgeInsets viewmargin; /* the view has this much extra margin beyond the window state's bounding box */
	
	CmdTextField *inputfield; /* if input is happening (but not necessarily a subview of this view) */
	UIScrollView *inputholder; /* terrible hack: all textfields must be wrapped in a UIScrollView container of the same size. */
	int input_request_id; /* matches the value in the GlkWindow if this input field is current */
	BOOL input_single_char; /* if we're grabbing character (rather than line) input */
	
	BOOL morewaiting; /* only used for buffer windows */
}

@property (nonatomic, strong) GlkWindowState *winstate;
@property (nonatomic, strong) StyleSet *styleset;
@property (nonatomic) UIEdgeInsets viewmargin;
@property (nonatomic, strong) CmdTextField *inputfield;
@property (nonatomic, strong) UIScrollView *inputholder;
@property (nonatomic) BOOL morewaiting;

- (id) initWithWindow:(GlkWindowState *)winstate frame:(CGRect)box margin:(UIEdgeInsets)margin;
- (GlkFrameView *) superviewAsFrameView;
- (void) updateFromWindowState;
- (void) updateFromWindowInputs;
- (void) uncacheLayoutAndStyles;

- (CGRect) textSelectArea;
- (void) setMoreFlag:(BOOL)flag;
- (void) placeInputField:(UITextField *)field holder:(UIScrollView *)holder;
- (void) textFieldContinueReturn:(UITextField *)textField;
- (void) postInputMenu;

@end
