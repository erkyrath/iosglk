/* GlkWinGridView.m: Glk textgrid window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "GlkWinGridView.h"
#import "GlkWindowState.h"
#import "GlkAppWrapper.h"
#import "StyleSet.h"
#import "CmdTextField.h"
#import "GlkUtilTypes.h"
#import "GlkUtilities.h"


@implementation GlkWinGridView

@synthesize lines;

- (id) initWithWindow:(GlkWindowState *)winref frame:(CGRect)box {
	self = [super initWithWindow:winref frame:box];
	if (self) {
		self.lines = [NSMutableArray arrayWithCapacity:8];
		self.backgroundColor = styleset.backgroundcolor;
		
		/* Without this contentMode setting, any window resize would cause weird font scaling. */
		self.contentMode = UIViewContentModeRedraw;
	}
	return self;
}

- (void) dealloc {
	self.lines = nil;
	[super dealloc];
}

- (void) uncacheLayoutAndStyles {
	if (inputfield)
		[inputfield adjustForWindowStyles:styleset];
	self.backgroundColor = styleset.backgroundcolor;
	[self setNeedsDisplay];
}

- (void) layoutSubviews {
	//NSLog(@"GridView: layoutSubviews");
	//### need to move or resize the text input view here
}

- (void) drawRect:(CGRect)rect {
	//NSLog(@"GridView: drawRect");
	CGContextRef gc = UIGraphicsGetCurrentContext();
	
	UIFont **fonts = styleset.fonts;
	UIColor **colors = styleset.colors;
	CGSize charbox = styleset.charbox;
	CGPoint marginoffset;
	marginoffset.x = styleset.margins.left;
	marginoffset.y = styleset.margins.top;
	
	/* We'll be using a limited list of colors, so it makes sense to track them by identity. */
	UIColor *lastcolor = nil;
	
	int jx = 0;
	for (GlkStyledLine *sln in lines) {
		CGPoint pt;
		pt.y = marginoffset.y + jx * charbox.height;
		for (GlkStyledString *str in sln.arr) {
			UIColor *color = colors[str.style];
			if (color != lastcolor) {
				CGContextSetFillColorWithColor(gc, color.CGColor);
				lastcolor = color;
			}
			pt.x = marginoffset.x + str.pos * charbox.width;
			[str.str drawAtPoint:pt withFont:fonts[str.style]];
		}
		jx++;
	}
}

- (void) updateFromWindowState {
	GlkWindowGridState *gridwin = (GlkWindowGridState *)winstate;
	BOOL anychanges = NO;
	
	for (GlkStyledLine *sln in gridwin.lines) {
		if (sln.index < lines.count)
			[lines replaceObjectAtIndex:sln.index withObject:sln];
		else
			[lines addObject:sln];
		anychanges = YES;
	}
	
	int height = gridwin.height;
	while (lines.count > height) {
		[lines removeLastObject];
		anychanges = YES;
	}
	
	if (!anychanges)
		return;
	
	[self setNeedsDisplay];
}

- (void) placeInputField:(UITextField *)field holder:(UIScrollView *)holder {
	GlkWindowGridState *gridwin = (GlkWindowGridState *)winstate;
	
	CGSize charbox = styleset.charbox;
	CGRect box;
	CGPoint marginoffset;
	marginoffset.x = styleset.margins.left;
	marginoffset.y = styleset.margins.top;
	
	box.origin.x = marginoffset.x + gridwin.curx * charbox.width;
	if (box.origin.x >= self.bounds.size.width * 0.75)
		box.origin.x = self.bounds.size.width * 0.75;
	box.size.width = self.bounds.size.width - box.origin.x;
	box.origin.y = marginoffset.y + gridwin.cury * charbox.height;
	box.size.height = 24;
	if (box.origin.y + box.size.height > self.bounds.size.height)
		box.origin.y = self.bounds.size.height - box.size.height;
		
	field.frame = CGRectMake(0, 0, box.size.width, box.size.height);
	holder.contentSize = box.size;
	holder.frame = box;
	if (!holder.superview)
		[self addSubview:holder];
}

@end

