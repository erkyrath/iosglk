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
@synthesize moreview;
@synthesize nowcontentscrolling;

- (id) initWithWindow:(GlkWindow *)winref frame:(CGRect)box {
	self = [super initWithWindow:winref frame:box];
	if (self) {
		lastLayoutBounds = CGRectZero;
		self.textview = [[[StyledTextView alloc] initWithFrame:self.bounds styles:win.styleset] autorelease];
		//textview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		textview.delegate = self;
		[self addSubview:textview];
		
		CGRect rect = CGRectMake(box.size.width-32, box.size.height-32, 32, 32);
		self.moreview = [[[UIView alloc] initWithFrame:rect] autorelease];
		moreview.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
		moreview.backgroundColor = [UIColor redColor];
		moreview.userInteractionEnabled = NO;
		moreview.hidden = YES;
		[self addSubview:moreview];		
	}
	return self;
}

- (void) dealloc {
	textview.delegate = nil;
	self.textview = nil;
	self.moreview = nil;
	[super dealloc];
}

/* This is called when the GlkFrameView changes size, and also (in iOS4) when the child scrollview scrolls. This is a mysterious mix of cases, but we can safely ignore the latter by only acting when the bounds actually change. 
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
}

/* This is invoked whenever the user types something. If we're at a "more" prompt, it pages down once, and returns YES. Otherwise, it pages all the way to the bottom and returns NO.
 */
- (BOOL) pageDownOnInput {
	if (textview.moreToSee) {
		[textview pageDown];
		return YES;
	}
	
	[textview pageToBottom];
	return NO;
}

- (void) setMoreFlag:(BOOL)flag {
	if (morewaiting == flag)
		return;
	
	morewaiting = flag;
	moreview.hidden = !flag;
	
	nowcontentscrolling = NO;
}

/* Either the text field is brand-new, or last cycle's text field needs to be adjusted for a new request. Add it as a subview (if necessary), and move it to the right place.
*/
- (void) placeInputField:(UITextField *)field holder:(UIScrollView *)holder {
	CGRect box = [textview placeForInputField];
	NSLog(@"WBV: input field goes to %@", StringFromRect(box));
	
	field.frame = CGRectMake(0, 0, box.size.width, box.size.height);
	holder.contentSize = box.size;
	holder.frame = box;
	if (!holder.superview)
		[textview addSubview:holder];
}

- (void) scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
	if (nowcontentscrolling && textview.moreToSee)
		[self setMoreFlag:YES];
}


@end
