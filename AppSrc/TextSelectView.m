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
		
		self.userInteractionEnabled = NO;
		
		self.shadeview = [[[UIView alloc] initWithFrame:area] autorelease];
		shadeview.backgroundColor = [UIColor colorWithRed:0.35 green:0.5 blue:1 alpha:0.33];
		shadeview.opaque = NO;
		[self addSubview:shadeview];
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

@end
