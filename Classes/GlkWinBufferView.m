/* GlkWinBufferView.m: Glk textbuffer window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "GlkWinBufferView.h"
#import "GlkWindow.h"
#import "GlkUtilTypes.h"

#import "StyledTextView.h"
#include "GlkUtilities.h"

@implementation GlkWinBufferView

@synthesize scrollview;
@synthesize textview;
@synthesize scrollDownNextLayout;

- (id) initWithWindow:(GlkWindow *)winref frame:(CGRect)box {
	self = [super initWithWindow:winref frame:box];
	if (self) {
		self.scrollview = [[[UIScrollView alloc] initWithFrame:self.bounds] autorelease];
		self.textview = [[[StyledTextView alloc] initWithFrame:self.bounds] autorelease];
		scrollview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		scrollview.alwaysBounceVertical = YES;
		scrollview.contentSize = self.bounds.size;
		textview.styleset = win.styleset;
		[scrollview addSubview:textview];
		[self addSubview:scrollview];
	}
	return self;
}

- (void) dealloc {
	self.textview = nil;
	self.scrollview = nil;
	[super dealloc];
}

- (void) scrollToBottom {
	CGFloat totalheight = [textview totalHeight];
	
	if (totalheight < self.bounds.size.height)
		return;
		
	CGRect box;
	box.origin = CGPointZero;
	box.size = self.bounds.size;
	box.origin.y = totalheight-1;
	box.size.height = 1;
	[scrollview scrollRectToVisible:box animated:YES];
}

//### I really shouldn't be doing this here at all. Maybe?
- (void) layoutSubviews {
	//NSLog(@"WBV: layoutSubviews to %@", StringFromRect(self.bounds));
	
	[textview setTotalWidth:scrollview.bounds.size.width];

	CGRect box;
	box.origin = CGPointZero;
	box.size = self.bounds.size;
	CGFloat totalheight = [textview totalHeight];
	if (box.size.height < totalheight)
		box.size.height = totalheight;
	textview.frame = box;
	[textview setNeedsDisplay];
	
	if (textfield) {
		CGRect tfbox = [textview placeForInputField];
		textfield.frame = tfbox;
	}
	
	scrollview.contentSize = box.size;
}

- (void) updateFromWindowState {
	GlkWindowBuffer *bufwin = (GlkWindowBuffer *)win;
	
	NSMutableArray *updates = bufwin.updatetext;
	if (updates.count == 0) {
		if (scrollDownNextLayout)
			[self scrollToBottom];
		scrollDownNextLayout = NO;
		return;
	}
	
	[textview updateWithLines:updates];
	[bufwin.updatetext removeAllObjects];
	
	CGFloat totalheight = [textview totalHeight];
	
	CGRect box;
	box.origin = CGPointZero;
	box.size = self.bounds.size;
	if (box.size.height < totalheight)
		box.size.height = totalheight;
	textview.frame = box;
	[textview setNeedsDisplay];
	scrollview.contentSize = box.size;
	
	[self scrollToBottom];
	scrollDownNextLayout = NO;
}

- (void) placeInputField:(UITextField *)field {
	CGRect box = [textview placeForInputField];
	field.frame = box;
	[textview addSubview:field];

	CGFloat totalheight = [textview totalHeight];
	
	box.origin = CGPointZero;
	box.size = self.bounds.size;
	if (box.size.height < totalheight)
		box.size.height = totalheight;
	scrollview.contentSize = box.size;
	
	[self scrollToBottom];
	scrollDownNextLayout = NO;
}

@end
