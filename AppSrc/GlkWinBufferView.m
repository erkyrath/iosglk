/* GlkWinBufferView.m: Glk textbuffer window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "GlkWinBufferView.h"
#import "GlkWindow.h"
#import "GlkUtilTypes.h"

#import "CmdTextField.h"
#import "StyledTextView.h"
#import "StyleSet.h"
#import "GlkUtilities.h"

@implementation GlkWinBufferView

@synthesize textview;

- (id) initWithWindow:(GlkWindow *)winref frame:(CGRect)box {
	self = [super initWithWindow:winref frame:box];
	if (self) {
		lastLayoutBounds = CGRectZero;
		self.textview = [[[StyledTextView alloc] initWithFrame:self.bounds styles:win.styleset] autorelease];
		//textview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubview:textview];
	}
	return self;
}

- (void) dealloc {
	self.textview = nil;
	[super dealloc];
}

/* Called when there is new output or a new input field.

	One irritating case is when new output appears at the same time as a screen resize. (For example, if a timer cancels line input and then prints some output.) This will be called *before* the layoutSubviews call hits, so we'll be scrolling to the wrong place. The resize's scroll-adjustment should take care of that.
*/
- (void) scrollToBottom:(BOOL)animated {
	return; //####
	
	CGFloat totalheight = [textview totalHeight];
	CGFloat curheight = self.bounds.size.height;
	//NSLog(@"### WBV: scrollToBottom, height %.1f, totalheight %.1f, diff (target) is %.1f", curheight, totalheight, totalheight - curheight);
	
	if (totalheight < curheight)
		return;
	
	CGPoint pt;
	pt.x = 0;
	pt.y = totalheight - curheight;
	
	/* I'm not using setContentOffset:animated: here, because that produces nasty weird animations. Specifically, if the scrollview changes size in the near future -- which can easily happen, if an output update is followed by the keyboard closing -- then the setContentOffset animation will continue to the original scroll position. Even if that's outside the bounds of the new scrollview size. There's no way to interrupt it. 
	
		So we run our own animation. (Fortunately, contentOffset is an animatable property.) */
	
	if (!animated) {
		textview.contentOffset = pt;
	}
	else {
		[UIView beginAnimations:@"autoscroll" context:nil];
		[UIView setAnimationDuration:0.3];
		[UIView setAnimationCurve:UIViewAnimationCurveLinear];
		textview.contentOffset = pt;
		[UIView commitAnimations];
	}
}

/* This is called when the GlkFrameView changes size, and also when the child scrollview scrolls. This is a mysterious mix of cases, but we can safely ignore the latter by only acting when the bounds actually change. 
*/
- (void) layoutSubviews {
	[super layoutSubviews];

	if (CGRectEqualToRect(lastLayoutBounds, self.bounds)) {
		return;
	}
	lastLayoutBounds = self.bounds;
	NSLog(@"WBV: layoutSubviews to %@", StringFromRect(self.bounds));
	
	textview.frame = self.bounds;
	[textview setNeedsLayout];
}

- (void) updateFromWindowState {
	GlkWindowBuffer *bufwin = (GlkWindowBuffer *)win;
	
	NSMutableArray *updates = bufwin.updatetext;
	if (updates.count == 0) {
		return;
	}
	
	[textview updateWithLines:updates];
	[bufwin.updatetext removeAllObjects];
	
	[textview setNeedsDisplay];
	
	//###[self scrollToBottom:YES];
}

/* Either the text field is brand-new, or last cycle's text field needs to be adjusted for a new request. Add it as a subview (if necessary), and move it to the right place. Also we'll want to scroll down.
*/
- (void) placeInputField:(UITextField *)field holder:(UIScrollView *)holder {
	CGRect box = [textview placeForInputField];
	NSLog(@"WBV: input field goes to %@", StringFromRect(box));
	
	field.frame = CGRectMake(0, 0, box.size.width, box.size.height);
	holder.contentSize = box.size;
	holder.frame = box;
	if (!holder.superview)
		[textview addSubview:holder];

	//###[self scrollToBottom:YES];
}

@end
