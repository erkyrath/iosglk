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
@synthesize vertalign;
@synthesize horizalign;

- (instancetype) initWithFrame:(CGRect)frame centerInFrame:(CGRect)rect {
	return [self initWithFrame:frame buttonFrame:rect vertAlign:0 horizAlign:0];
}

- (instancetype) initWithFrame:(CGRect)frame buttonFrame:(CGRect)rect belowButton:(BOOL)below {
	int horval = (below ? 1 : -1);
	int vertval = horval;
	
	return [self initWithFrame:frame buttonFrame:rect vertAlign:vertval horizAlign:horval];
}

- (instancetype) initWithFrame:(CGRect)frame buttonFrame:(CGRect)rect vertAlign:(int)vertval horizAlign:(int)horval {
	self = [super initWithFrame:frame];
	if (self) {
		//self.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5]; //###
		horizalign = horval;
		vertalign = vertval;
		buttonrect = rect;
	}
	return self;
}


- (GlkFrameView *) superviewAsFrameView {
	return (GlkFrameView *)self.superview;
}

- (NSString *) bottomDecorNib {
	return nil;
}

- (void) loadContent {
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
	view.backgroundColor = [UIColor redColor];
	view.layer.cornerRadius = 10;
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[self resizeContentTo:view.frame.size animated:NO];
	view.frame = content.bounds;
	[content addSubview:view];
}

- (void) resizeContentTo:(CGSize)size animated:(BOOL)animated {
	CGRect rect = CGRectMake(0, 0, size.width+framemargins.left+framemargins.right, size.height+framemargins.top+framemargins.bottom);
	
	if (vertalign > 0) {
		rect.origin.y = (buttonrect.origin.y + buttonrect.size.height);
	}
	else if (vertalign < 0) {
		rect.origin.y = buttonrect.origin.y - rect.size.height;
		if (rect.origin.y < 0)
			rect.origin.y = 0;
	}
	else {
		CGFloat mid = buttonrect.origin.y + 0.5*buttonrect.size.height;
		rect.origin.y = floorf(mid - 0.5*rect.size.height);
	}
	
	if (horizalign > 0) {
		rect.origin.x = buttonrect.origin.x;
	}
	else if (horizalign < 0) {
		rect.origin.x = (buttonrect.origin.x + buttonrect.size.width) - rect.size.width;
	}
	else {
		CGFloat mid = buttonrect.origin.x + 0.5*buttonrect.size.width;
		rect.origin.x = floorf(mid - 0.5*rect.size.width);
	}
	
	if (animated && self.superview) {
		[UIView animateWithDuration:0.25 
                         animations:^{ self->frameview.frame = rect; } ];
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
