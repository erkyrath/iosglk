/* PopMenuView.m: Base class for on-screen pop-up menus
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import "PopMenuView.h"
#import "IosGlkAppDelegate.h"
#import "GlkFrameView.h"
#import "GlkUtilities.h"

@implementation PopMenuView

@synthesize frameview;
@synthesize content;
@synthesize decor;
@synthesize faderview;
@synthesize framemargins;
@synthesize buttonrect;
@synthesize belowbutton;

- (id) initWithFrame:(CGRect)frame buttonFrame:(CGRect)rect belowButton:(BOOL)below {
	self = [super initWithFrame:frame];
	if (self) {
		//self.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5]; //###
		belowbutton = below;
		buttonrect = rect;
	}
	return self;
}

- (void) dealloc {
	self.frameview = nil;
	self.content = nil;
	self.decor = nil;
	self.faderview = nil;
	[super dealloc];
}

- (GlkFrameView *) superviewAsFrameView {
	return (GlkFrameView *)self.superview;
}

- (NSString *) bottomDecorNib {
	return nil;
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
	
	if (belowbutton) {
		rect.origin.x = buttonrect.origin.x;
		rect.origin.y = (buttonrect.origin.y + buttonrect.size.height);
	}
	else {
		rect.origin.x = (buttonrect.origin.x + buttonrect.size.width) - rect.size.width;
		rect.origin.y = buttonrect.origin.y - rect.size.height;
	}
	
	if (animated && [IosGlkAppDelegate animblocksavailable] && self.superview) {
		[UIView animateWithDuration:0.25 
						 animations:^{ frameview.frame = rect; } ];
	}
	else {
		frameview.frame = rect;
	}
}

- (void) willRemove {
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[self.superviewAsFrameView removePopMenuAnimated:YES];
}


@end
