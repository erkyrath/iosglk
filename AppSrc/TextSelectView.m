/* TextSelectView.m: View for a text-selection overlap
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import "TextSelectView.h"

@implementation TextSelectView

@synthesize shadeview;
@synthesize outlineview;

- (id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		area = CGRectZero;
		outline = CGRectZero;
		outlinevisible = NO;
		
		self.userInteractionEnabled = NO;
		self.clipsToBounds = NO;
		
		self.shadeview = [[[UIView alloc] initWithFrame:area] autorelease];
		shadeview.backgroundColor = [UIColor colorWithRed:0.35 green:0.5 blue:1 alpha:0.33];
		shadeview.opaque = NO;
		[self addSubview:shadeview];
		
		self.outlineview = [[[TextOutlineView alloc] initWithFrame:area] autorelease];
		outlineview.alpha = 0;
		[self addSubview:outlineview];
	}
	return self;
}

- (void) dealloc {
	self.shadeview = nil;
	self.outlineview = nil;
	[super dealloc];
}

- (void) setArea:(CGRect)box {
	area = box;
	shadeview.frame = area;
}

- (void) setOutline:(CGRect)box animated:(BOOL)animated {
	outline = CGRectInset(box, 0, -2);
	
	if (!animated) {
		outlineview.frame = outline;
		if (!outlinevisible)
			outlineview.alpha = 1;
	}
	else {
		[UIView beginAnimations:@"seloutlineMove" context:nil];
		[UIView setAnimationDuration:0.2];
		outlineview.frame = outline;
		if (!outlinevisible)
			outlineview.alpha = 1;
		[UIView commitAnimations];
	}

	outlinevisible = YES;
}

- (void) hideOutlineAnimated:(BOOL)animated {
	if (!outlinevisible) 
		return;
	
	outlinevisible = NO;
	
	if (!animated) {
		outlineview.alpha = 0;
	}
	else {
		[UIView beginAnimations:@"seloutlineHide" context:nil];
		[UIView setAnimationDuration:0.2];
		outlineview.alpha = 0;
		[UIView commitAnimations];
	}
}

@end


@implementation TextOutlineView

- (id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		self.opaque = NO;
		self.contentMode = UIViewContentModeRedraw;
		self.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
	}
	return self;
}

- (void) drawRect:(CGRect)cliprect {
	CGContextRef gc = UIGraphicsGetCurrentContext();
	
	CGRect rect = self.bounds;
	
	CGContextSetRGBStrokeColor(gc, 0.35, 0.5, 1, 0.8);
	CGContextSetLineWidth(gc, 2);
	CGContextStrokeRect(gc, CGRectInset(rect, 1, 1));
}

@end

