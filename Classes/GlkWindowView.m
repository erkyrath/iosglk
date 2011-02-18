/* GlkWindowView.m: Base class for a Glk window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	From the library's point of view, a Glk window (GlkWindow object) is a data object. It is represented on-screen by a view object, which is a subclass of GlkWindowView. These windowviews are children of the GlkFrameView.

	(We don't try to follow the Cocoa model of data changes triggering view changes. GlkWindows are totally inert. The GlkFrameView will tip us off when it's time for the windowview to update.)
*/

#import "GlkWindowView.h"
#import "GlkWinBufferView.h"
#import "GlkWinGridView.h"
#import "GlkWindow.h"
#include "GlkUtilities.h"

@implementation GlkWindowView

@synthesize win;
@synthesize textfield;

+ (GlkWindowView *) viewForWindow:(GlkWindow *)win {
	switch (win.type) {
		case wintype_TextBuffer:
			return [[[GlkWinBufferView alloc] initWithWindow:win frame:win.bbox] autorelease];
		case wintype_TextGrid:
			return [[[GlkWinGridView alloc] initWithWindow:win frame:win.bbox] autorelease];
		default:
			[NSException raise:@"GlkException" format:@"no windowview class for this window"];
			return nil; // not really
	}
}


- (id) initWithWindow:(GlkWindow *)winref frame:(CGRect)box {
	self = [super initWithFrame:box];
	if (self) {
		self.win = winref;
		self.textfield = nil;
	}
	return self;
}

- (void) dealloc {
	self.textfield = nil;
	self.win = nil;
	[super dealloc];
}

/* The windowview subclasses will override this. */
- (void) updateFromWindowState {
	[NSException raise:@"GlkException" format:@"updateFromWindowState not implemented"];
}

- (void) updateFromWindowSize {
	self.frame = self.win.bbox;
}

- (void) updateFromWindowInputs {
	if (textfield) {
		if (!win.line_request || win.line_request_id != line_request_id) {
			/* This input field is obsolete, or it's changed. Get rid of it. */
			[textfield removeFromSuperview];
			self.textfield = nil;
		}
	}
	
	if (!textfield) {
		if (win.line_request) {
			line_request_id = win.line_request_id;
			CGRect box;
			box.origin.x = 0;
			box.origin.y = 16;
			box.size.width = self.bounds.size.width;
			box.size.height = 24;
			self.textfield = [[[UITextField alloc] initWithFrame:box] autorelease];
			textfield.backgroundColor = [UIColor whiteColor];
			textfield.borderStyle = UITextBorderStyleBezel;
			textfield.autocapitalizationType = UITextAutocapitalizationTypeNone;
			textfield.keyboardType = UIKeyboardTypeASCIICapable;
			textfield.returnKeyType = UIReturnKeyGo;
			[self addSubview:textfield]; //### wrong
		}
	}
}

@end
