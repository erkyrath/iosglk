/* TextSelectView.m: View for a text-selection overlap
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import "TextSelectView.h"
#import "IosGlkAppDelegate.h"

@implementation TextSelectView

@synthesize shadeview;
@synthesize outlineview;
@synthesize tophandleview;
@synthesize bottomhandleview;


- (id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		area = CGRectZero;
		outline = CGRectZero;
		outlinevisible = NO;
		
		self.userInteractionEnabled = NO;
		self.clipsToBounds = NO;
		
		self.shadeview = [[UIView alloc] initWithFrame:area];
		shadeview.backgroundColor = [UIColor colorWithRed:0.35 green:0.5 blue:1 alpha:0.33];
		shadeview.opaque = NO;
		[self addSubview:shadeview];
		
		self.outlineview = [[TextOutlineView alloc] initWithFrame:area];
		outlineview.alpha = 0;
		[self addSubview:outlineview];
		
		UIImage *img = [UIImage imageNamed:@"selecthandle"];
		self.tophandleview = [[UIImageView alloc] initWithImage:img];
		tophandleview.hidden = YES;
		self.bottomhandleview = [[UIImageView alloc] initWithImage:img];
		bottomhandleview.hidden = YES;

		[self addSubview:tophandleview];
		[self addSubview:bottomhandleview];
	}
	return self;
}


- (void) setArea:(CGRect)box {
	area = box;
	shadeview.frame = area;
	
	CGFloat xpos = area.origin.x + floorf(0.5*area.size.width);
	tophandleview.center = CGPointMake(xpos, area.origin.y);
	bottomhandleview.center = CGPointMake(xpos, area.origin.y+area.size.height);
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
	
	tophandleview.hidden = YES;
	bottomhandleview.hidden = YES;
}

- (void) hideOutlineAnimated:(BOOL)animated {
	if (!outlinevisible) 
		return;
	
	if (!animated) {
		outlineview.alpha = 0;
	}
	else {
		[UIView beginAnimations:@"seloutlineHide" context:nil];
		[UIView setAnimationDuration:0.2];
		outlineview.alpha = 0;
		[UIView commitAnimations];
	}
	
	outlinevisible = NO;
	
	tophandleview.hidden = NO;
	bottomhandleview.hidden = NO;
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

