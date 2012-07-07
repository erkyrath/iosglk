/* GlkWinBufferView.m: Glk textbuffer window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "GlkWinBufferView.h"
#import "IosGlkAppDelegate.h"
#import "IosGlkViewController.h"
#import "GlkLibrary.h"
#import "GlkWindowState.h"
#import "GlkLibraryState.h"
#import "GlkUtilTypes.h"

#import "CmdTextField.h"
#import "StyledTextView.h"
#import "MoreBoxView.h"
#import "StyleSet.h"
#import "GlkUtilities.h"

@implementation GlkWinBufferView

@synthesize textview;
@synthesize moreview;
@synthesize nowcontentscrolling;

- (id) initWithWindow:(GlkWindowState *)winref frame:(CGRect)box margin:(UIEdgeInsets)margin {
	self = [super initWithWindow:winref frame:box margin:margin];
	if (self) {
		self.contentMode = UIViewContentModeRedraw;
		self.backgroundColor = [UIColor clearColor];
		
		lastLayoutBounds = CGRectNull;
		self.textview = [[[StyledTextView alloc] initWithFrame:self.bounds margin:margin styles:styleset] autorelease];
		//textview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		textview.delegate = self;
		[self addSubview:textview];
		
		self.moreview = [[[MoreBoxView alloc] initWithFrame:CGRectZero] autorelease];
		[[NSBundle mainBundle] loadNibNamed:@"MoreBoxView" owner:moreview options:nil];
		CGRect rect = moreview.frameview.frame;
		rect.origin.x = MIN(box.size.width - viewmargin.right + 4, box.size.width - (rect.size.width + 4));
		rect.origin.y = box.size.height - (rect.size.height + 4);
		moreview.frame = rect;
		[moreview addSubview:moreview.frameview];
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
	//NSLog(@"WBV: layoutSubviews to %@", StringFromRect(self.bounds));
	
	CGRect rect = moreview.frameview.frame;
	rect.origin.x = MIN(lastLayoutBounds.size.width - viewmargin.right + 4, lastLayoutBounds.size.width - (rect.size.width + 4));
	rect.origin.y = lastLayoutBounds.size.height - (rect.size.height + 4);
	moreview.frame = rect;
	
	textview.frame = lastLayoutBounds;
	textview.viewmargin = viewmargin;
	[textview setNeedsLayout];
	[textview setNeedsDisplay];
}

- (void) uncacheLayoutAndStyles {
	[textview acceptStyleset:styleset];
	if (inputfield)
		[inputfield adjustForWindowStyles:styleset];
	lastLayoutBounds = CGRectNull;
	[textview uncacheLayoutAndVLines:YES];
}

- (void) updateFromWindowState {
	GlkWindowBufferState *bufwin = (GlkWindowBufferState *)winstate;
	
	//NSLog(@"WBV: updateFromWindowState: %d lines (dirty %d to %d)", bufwin.lines.count, bufwin.linesdirtyfrom, bufwin.linesdirtyto);
	if (bufwin.linesdirtyfrom >= bufwin.linesdirtyto)
		return;
	
	[textview updateWithLines:bufwin.lines dirtyFrom:bufwin.linesdirtyfrom clearCount:bufwin.clearcount refresh:bufwin.library.everythingchanged];
	[textview setNeedsDisplay];
}

/* This is invoked whenever the user types something. If we're at a "more" prompt, it pages down once, and returns YES. Otherwise, it pages all the way to the bottom and returns NO.
 */
- (BOOL) pageDownOnInput {
	if (textview.moreToSee) {
		[textview pageDown:self];
		return YES;
	}
	
	[textview pageToBottom];
	return NO;
}

- (CGRect) textSelectArea {
	if (!textview.anySelection)
		return CGRectNull;
	return textview.selectionarea;
}

- (void) setMoreFlag:(BOOL)flag {
	if (morewaiting == flag)
		return;
	
	/* NoMorePrompt is a preference that I decided to drop.
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL usemore = ![defaults boolForKey:@"NoMorePrompt"];
	if (!usemore)
		return;
	 */
	
	morewaiting = flag;
	if (flag) {
		if ([IosGlkAppDelegate animblocksavailable]) {
			moreview.alpha = 0;
			moreview.hidden = NO;
			[UIView animateWithDuration:0.2 
							 animations:^{ moreview.alpha = 0.5; } ];
		}
		else {
			moreview.hidden = NO;
		}
	}
	else {
		if ([IosGlkAppDelegate animblocksavailable]) {
			[UIView animateWithDuration:0.2 
							 animations:^{ moreview.alpha = 0; }
							 completion:^(BOOL finished) { moreview.hidden = YES; } ];
		}
		else {
			moreview.hidden = YES;
		}
	}
	
	nowcontentscrolling = NO;
}

/* Either the text field is brand-new, or last cycle's text field needs to be adjusted for a new request. Add it as a subview of the textview (if necessary), and move it to the right place.
*/
- (void) placeInputField:(UITextField *)field holder:(UIScrollView *)holder {
	CGRect box = [textview placeForInputField];
	//NSLog(@"WBV: input field goes to %@", StringFromRect(box));
	
	field.frame = CGRectMake(0, 0, box.size.width, box.size.height);
	holder.contentSize = box.size;
	holder.frame = box;
	if (!holder.superview)
		[textview addSubview:holder];
}

/* UIScrollView delegate methods: */

- (void) scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
	if (nowcontentscrolling) {
		/* If the scroll animation left us below the desired bottom edge, we'll extend the content height to include it. But only temporarily! This is to avoid jerkiness when the player scrolls to recover. */
		CGFloat offset = (textview.contentOffset.y+textview.bounds.size.height) - textview.contentSize.height;
		if (offset > 1) {
			CGSize size = textview.contentSize;
			size.height += offset;
			textview.contentSize = size;
		}
	}
	
	if (nowcontentscrolling && textview.moreToSee)
		[self setMoreFlag:YES];
	if (textview.anySelection)
		[textview showSelectionMenu];
}

- (void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if (!decelerate) {
		if (textview.anySelection)
			[textview showSelectionMenu];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	if (textview.anySelection)
		[textview showSelectionMenu];
}

@end
