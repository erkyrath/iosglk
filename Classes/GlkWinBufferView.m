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

- (id) initWithWindow:(GlkWindow *)winref frame:(CGRect)box {
	self = [super initWithWindow:winref frame:box];
	if (self) {
		lastLayoutBounds = CGRectZero;
		willClampScrollAnim = YES;
		self.scrollview = [[[UIScrollView alloc] initWithFrame:self.bounds] autorelease];
		self.textview = [[[StyledTextView alloc] initWithFrame:self.bounds] autorelease];
		scrollview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		scrollview.alwaysBounceVertical = YES;
		scrollview.contentSize = self.bounds.size;
		scrollview.delegate = self;
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

- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	//NSLog(@"scrollview: WillBeginDragging");
	willClampScrollAnim = NO;
}

/* Called when there is new output or a new input field.

	One irritating case is when new output appears at the same time as a screen resize. (For example, if a timer cancels line input and then prints some output.) This will be called *before* the layoutSubviews call hits, so we'll be scrolling to the wrong place. The resize's scroll-adjustment should take care of that.
*/
- (void) scrollToBottom:(BOOL)animated {
	CGFloat totalheight = [textview totalHeight];
	CGFloat curheight = self.bounds.size.height;
	//NSLog(@"### WBV: scrollToBottom, height %.1f, totalheight %.1f, diff (target) is %.1f", curheight, totalheight, totalheight - curheight);
	
	if (totalheight < curheight)
		return;
	
	willClampScrollAnim = YES;

	CGPoint pt;
	pt.x = 0;
	pt.y = totalheight - curheight;
	[scrollview setContentOffset:pt animated:animated];
}

/* This is called when the GlkFrameView changes size, and also when the child scrollview scrolls. This is a mysterious mix of cases, but we can safely ignore the latter by only acting when the bounds actually change. 
*/
//### I really shouldn't be doing this here at all. Maybe?
- (void) layoutSubviews {
	if (CGRectEqualToRect(lastLayoutBounds, self.bounds)) {
		//NSLog(@"### boring layoutSubviews; scroll pos is %.1f of %.1f", scrollview.contentOffset.y, scrollview.contentSize.height - scrollview.bounds.size.height);
		if (willClampScrollAnim) {
			CGFloat scrollmax = scrollview.contentSize.height - scrollview.bounds.size.height;
			if (scrollview.contentOffset.y > scrollmax) {
				NSLog(@"...abort scroll!");
				CGPoint pt = CGPointMake(0, scrollmax);
				[scrollview setContentOffset:pt animated:NO];
			}
		}
		return;
	}
	lastLayoutBounds = self.bounds;
	NSLog(@"WBV: layoutSubviews to %@", StringFromRect(self.bounds));
	
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
	[self scrollToBottom:NO];
}

- (void) updateFromWindowState {
	GlkWindowBuffer *bufwin = (GlkWindowBuffer *)win;
	
	NSMutableArray *updates = bufwin.updatetext;
	if (updates.count == 0) {
		//if (scrollDownNextLayout)
		//	[self scrollToBottom];
		//scrollDownNextLayout = NO;
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
	
	[self scrollToBottom:YES];
	//scrollDownNextLayout = NO;
}

/* Either the text field is brand-new, or last cycle's text field needs to be adjusted for a new request. Add it as a subview (if necessary), and move it to the right place. Also we'll want to scroll down.
*/
- (void) placeInputField:(UITextField *)field {
	CGRect box = [textview placeForInputField];
	field.frame = box;
	if (!field.superview)
		[textview addSubview:field];

	CGFloat totalheight = [textview totalHeight];
	
	box.origin = CGPointZero;
	box.size = self.bounds.size;
	if (box.size.height < totalheight)
		box.size.height = totalheight;
	scrollview.contentSize = box.size;
	
	[self scrollToBottom:YES];
	//scrollDownNextLayout = NO;
}

@end
