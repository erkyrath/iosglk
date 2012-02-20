//
//  PopBoxView.m
//  IosFizmo
/* PopMenuView.m: Base class for on-screen pop-up menus
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import "PopMenuView.h"
#import "GlkFrameView.h"
#import "GlkUtilities.h"

@implementation PopMenuView

@synthesize frameview;
@synthesize content;
@synthesize framemargins;
@synthesize buttonrect;

- (id) initWithFrame:(CGRect)frame buttonFrame:(CGRect)rect {
	self = [super initWithFrame:frame];
	if (self) {
		//self.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5]; //###
		buttonrect = rect;
	}
	return self;
}

- (void) dealloc {
	self.frameview = nil;
	self.content = nil;
	[super dealloc];
}

- (GlkFrameView *) superviewAsFrameView {
	return (GlkFrameView *)self.superview;
}

- (void) loadContent {
	UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)] autorelease];
	view.backgroundColor = [UIColor redColor];
	view.layer.cornerRadius = 10;
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[self resizeContentTo:view.frame.size animated:NO];
	view.frame = content.bounds;
	[content addSubview:view];
}

- (void) resizeContentTo:(CGSize)size animated:(BOOL)animated {
	CGRect rect = CGRectMake(0, 0, size.width+framemargins.left+framemargins.right, size.height+framemargins.top+framemargins.bottom);
	
	rect.origin.x = (buttonrect.origin.x + buttonrect.size.width) - rect.size.width;
	rect.origin.y = buttonrect.origin.y - rect.size.height;
	
	frameview.frame = rect;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[self.superviewAsFrameView removePopMenu];
}


@end
