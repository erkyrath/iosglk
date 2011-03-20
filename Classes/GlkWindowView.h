/* GlkWindowView.h: Base class for a Glk window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>
#include "glk.h"

@class GlkWindow;

@interface GlkWindowView : UIView <UITextFieldDelegate> {
	GlkWindow *win;
	
	UITextField *textfield; /* if input is happening (but not necessarily a subview of this view) */
	int input_request_id; /* matches the value in the GlkWindow if this input field is current */
	BOOL input_single_char; /* if we're grabbing character (rather than line) input */
}

@property (nonatomic, retain) GlkWindow *win;
@property (nonatomic, retain) UITextField *textfield;

+ (GlkWindowView *) viewForWindow:(GlkWindow *)win;

- (id) initWithWindow:(GlkWindow *)winref frame:(CGRect)box;
- (void) updateFromWindowState;
- (void) updateFromWindowInputs;
//###- (void) updateFromWindowSize;

- (void) placeInputField:(UITextField *)field;
- (void) textFieldContinueReturn:(UITextField *)textField;

@end
