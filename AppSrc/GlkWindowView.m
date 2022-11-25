/* GlkWindowView.m: Base class for a Glk window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	From the library's point of view, a Glk window (GlkWindow object) is a data object. It is represented on-screen by a view object, which is a subclass of GlkWindowView. These windowviews are children of the GlkFrameView.

	(We don't try to follow the Cocoa model of data changes triggering view changes. GlkWindows are totally inert. The GlkFrameView will tip us off when it's time for the windowview to update.)
*/

#import "GlkWindowView.h"
#import "IosGlkViewController.h"
#import "GlkFrameView.h"
#import "GlkWinBufferView.h"
#import "GlkWinGridView.h"
#import "GlkLibrary.h"
#import "GlkLibraryState.h"
#import "GlkWindowState.h"
#import "GlkAppWrapper.h"
#import "GlkUtilities.h"
#import "CmdTextField.h"
#import "InputMenuView.h"
#import "StyleSet.h"
#import "GlkWindowViewUIState.h"
#import "IosGlkAppDelegate.h"

@implementation GlkWindowView

- (instancetype) initWithWindow:(GlkWindowState *)winstateref frame:(CGRect)box margin:(UIEdgeInsets)margin {
	self = [super initWithFrame:box];
	if (self) {
		_viewmargin = margin;
		self.winstate = winstateref;
        _tagobj = winstateref.tag;
		self.styleset = _winstate.styleset;
		_input_request_id = 0;
	}
	return self;
}

- (GlkFrameView *) superviewAsFrameView {
	return (GlkFrameView *)self.superview;
}

- (void) setViewmargin:(UIEdgeInsets)newmargin {
	_viewmargin = newmargin;
	[self setNeedsLayout];
}

/* Read data from the GlkWindow object, and update the view.
 
	The windowview subclasses will override this. */
- (void) updateFromWindowState {
	[NSException raise:@"GlkException" format:@"updateFromWindowState not implemented"];
}

/* Discard everything the window knows about its layout, fonts, colors, etc. Look at the current view.styleset to pick up new information. Windowview subclasses will override this. */
- (void) uncacheLayoutAndStyles {
	/* By default, do nothing. */
}

- (void) updateFromUIState:(NSDictionary *)state {
    if (self.inputfield) {
        self.inputfield.text = state[@"inputText"];

        NSNumber *location = state[@"inputSelectionLoc"];
        NSNumber *length = state[@"inputSelectionLen"];
        if (location && length) {
            UITextField *field = self.inputfield;
            UITextPosition *beginning = field.beginningOfDocument;
            UITextPosition *start = [field positionFromPosition:beginning offset:location.integerValue];
            UITextPosition *end = [field positionFromPosition:start offset:length.integerValue];
            self.inputfield.selectedTextRange = [field textRangeFromPosition:start toPosition:end];
        }
        NSNumber *inputIsFirstResponder = state[@"inputIsFirstResponder"];
        if (inputIsFirstResponder) {
            if (inputIsFirstResponder.integerValue == 1) {
                [self.inputfield becomeFirstResponder];
            } else {
                [self.inputfield resignFirstResponder];
            }
        }
    }
}



/* Read data from the GlkWindow object, and update the input field.
 */
- (void) updateFromWindowInputs {
	BOOL wants_input = (_winstate.char_request || _winstate.line_request) && (!_winstate.library.vmexited);
	
	/* The logic here will make more sense if you remember that any *change* in input request -- including a change from char to line input -- will be accompanied by a change in input_request_id. 
	
		That means that if we're puttering along with the same input request, we touch nothing. If an input request ends and a new one starts, we leave the same textfield on-screen (so that the keyboard stays up); we just adjust its position and its attributes.
		
		(If an input request is cancelled in one window and started in a different window, the keyboard will roll down. That's unfortunate, but we'll fix it later. It will require some coordinating between updateFromWindowInputs calls.) */
	
	if (!wants_input) {
		if (_inputfield) {
			/* The window doesn't want any input at all. Get rid of the textfield. */
			[self.superviewAsFrameView removePopMenuAnimated:YES];
			[_inputfield removeFromSuperview];
			[_inputholder removeFromSuperview];
			self.inputfield = nil;
			self.inputholder = nil;
			_input_request_id = 0;
		}
	}
	
	if (wants_input) {
		if (!_inputfield) {
			self.inputfield = [[CmdTextField alloc] initWithFrame:CGRectZero];
			self.inputfield.opaque = NO;
			self.inputfield.backgroundColor = nil;
			self.inputholder = [[UIScrollView alloc] initWithFrame:CGRectZero];
			self.inputholder.opaque = NO;
			self.inputholder.backgroundColor = nil;
			[_inputholder addSubview:_inputfield];
			_input_request_id = 0;
		}
		
		if (_input_request_id != _winstate.input_request_id) {
			/* Either the text field is brand-new, or last cycle's text field needs to be adjusted for a new request. */
			_input_request_id = _winstate.input_request_id;
			_input_single_char = _winstate.char_request;
			
			[_inputfield setUpForWindow:self singleChar:_input_single_char];
			
			/* This places the field correctly, and adds it as a subview if it isn't already. */
			[self placeInputField:_inputfield holder:_inputholder];
            [_inputfield becomeFirstResponder];
		}
	}
}

/* Decide where to place the input field.
 
 The windowview subclasses will override this. */
- (void) placeInputField:(UITextField *)field holder:(UIScrollView *)holder {
	[NSException raise:@"GlkException" format:@"placeInputField not implemented"];
}

/* Delegate methods for UITextField: */

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)str {
	if ([self isKindOfClass:[GlkWinBufferView class]]) {
		GlkWinBufferView *winv = (GlkWinBufferView *)self;
		if (winv.pageDownOnInput) {
			if (_input_single_char) {
				/* While paging: ignore everything, if we're waiting for char input. */
				return NO;
			}
			if (range.location == 0 && [@" " isEqualToString:str]) {
				/* Ignore the space bar too. */
				return NO;
			}
			if (str.length == 1 && range.location == 1 && [textField.text hasPrefix:str]) {
				/* Ignore repeated taps on the same character. */
				return NO;
			}
		}
	}
	
    if (_input_single_char) {
		if (str.length) {
			/* We should crunch utf16 characters here. */
			glui32 ch = [str characterAtIndex:(str.length-1)];
			if (_winstate.char_request)
				[[GlkAppWrapper singleton] acceptEvent:[GlkEventState charEvent:ch inWindow:_winstate.tag]];
		}
		return NO;
	}
	else {
		[self.superviewAsFrameView removePopMenuAnimated:YES];
	}
	return YES;
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
	if ([self isKindOfClass:[GlkWinBufferView class]]) {
		GlkWinBufferView *winv = (GlkWinBufferView *)self;
		if (winv.pageDownOnInput) {
			return NO;
		}
	}
	
    if (_input_single_char) {
		glui32 ch = keycode_Return;
		if (_winstate.char_request)
			[[GlkAppWrapper singleton] acceptEvent:[GlkEventState charEvent:ch inWindow:_winstate.tag]];
		return NO;
	}

	[self.superviewAsFrameView removePopMenuAnimated:YES];

	/* Don't look at the text yet; the last word hasn't been spellchecked. However, we don't want to close the keyboard either. The only good answer seems to be to fire a function call with a tiny delay, and return YES to ensure that the spellcheck is accepted. */
	[self performSelector:@selector(textFieldContinueReturn:) withObject:textField afterDelay:0.0];
	return YES;
}

- (void) textFieldContinueReturn:(UITextField *)textField {
	NSString *text = textField.text;
	//NSLog(@"End editing: '%@'", text);
	
	if (![GlkAppWrapper singleton].acceptingEvent) {
		/* The event must have been filled while we were delaying. Oh well. */
		return;
	}
	
	IosGlkViewController *glkviewc = [IosGlkViewController singleton];
	[glkviewc addToCommandHistory:text];
	
	if (!_winstate.line_request) {
		/* This window isn't accepting input. Oh well. */
		return; 
	}
	
	[[GlkAppWrapper singleton] acceptEvent:[GlkEventState lineEvent:text inWindow:_winstate.tag]];
}

- (void) postInputMenu {
	if (!_inputfield || _inputfield.singleChar)
		return;
	if (self.superviewAsFrameView.menuview)
		return;

	if (_inputfield && _inputfield.menubutton)
		_inputfield.menubutton.selected = YES;

	IosGlkViewController *glkviewc = [IosGlkViewController singleton];
	GlkFrameView *frameview = self.superviewAsFrameView;
	CGRect rect = [_inputfield rightViewRectForBounds:_inputfield.bounds];
	rect = [frameview convertRect:rect fromView:_inputfield];
	InputMenuView *menuview = [[InputMenuView alloc] initWithFrame:frameview.bounds buttonFrame:rect view:self history:glkviewc.commandhistory];
	[frameview postPopMenu:menuview];	
}

@end


