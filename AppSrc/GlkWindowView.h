/* GlkWindowView.h: Base class for a Glk window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>
#include "glk.h"

@class GlkWindow;
@class GlkFrameView;
@class CmdTextField;

@interface GlkWindowView : UIView <UITextFieldDelegate> {
	GlkWindow *win;
	
	CmdTextField *inputfield; /* if input is happening (but not necessarily a subview of this view) */
	UIScrollView *inputholder; /* terrible hack: all textfields must be wrapped in a UIScrollView container of the same size. */
	int input_request_id; /* matches the value in the GlkWindow if this input field is current */
	BOOL input_single_char; /* if we're grabbing character (rather than line) input */
	
	BOOL morewaiting; /* only used for buffer windows */
}

@property (nonatomic, retain) GlkWindow *win;
@property (nonatomic, retain) CmdTextField *inputfield;
@property (nonatomic, retain) UIScrollView *inputholder;
@property (nonatomic) BOOL morewaiting;

+ (GlkWindowView *) viewForWindow:(GlkWindow *)win;

- (id) initWithWindow:(GlkWindow *)winref frame:(CGRect)box;
- (GlkFrameView *) superviewAsFrameView;
- (void) updateFromWindowState;
- (void) updateFromWindowInputs;

- (void) setMoreFlag:(BOOL)flag;
- (void) placeInputField:(UITextField *)field holder:(UIScrollView *)holder;
- (void) textFieldContinueReturn:(UITextField *)textField;
- (void) postInputMenu;

@end
