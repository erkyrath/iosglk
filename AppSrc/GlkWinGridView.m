/* GlkWinGridView.m: Glk textgrid window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "GlkWinGridView.h"
#import "IosGlkAppDelegate.h" //###
#import "IosGlkViewController.h" //###
#import "GlkWindow.h"
#import "GlkAppWrapper.h"
#import "StyleSet.h"
#import "GlkUtilTypes.h"


@implementation GlkWinGridView

@synthesize lines;
@synthesize styleset;

- (id) initWithWindow:(GlkWindow *)winref frame:(CGRect)box {
	self = [super initWithWindow:winref frame:box];
	if (self) {
		self.lines = [NSMutableArray arrayWithCapacity:8];
		self.styleset = win.styleset;
		
		/* Without this contentMode setting, any window resize would cause weird font scaling. */
		self.contentMode = UIViewContentModeRedraw;
	}
	return self;
}

- (void) dealloc {
	self.lines = nil;
	self.styleset = nil;
	[super dealloc];
}

- (void) layoutSubviews {
	//NSLog(@"GridView: layoutSubviews");
	//### need to move or resize the text view here
}

- (void) drawRect:(CGRect)rect {
	//NSLog(@"GridView: drawRect");
	CGContextRef gc = UIGraphicsGetCurrentContext();
	CGContextSetRGBFillColor(gc,  1, 1, 1,  1);
	CGContextFillRect(gc, rect);
	
	CGContextSetRGBFillColor(gc,  0, 0, 0,  1);
	
	UIFont **fonts = styleset.fonts;
	CGSize charbox = styleset.charbox;
	CGPoint marginoffset = styleset.marginframe.origin;
	
	int jx = 0;
	for (GlkStyledLine *sln in lines) {
		CGPoint pt;
		pt.y = marginoffset.y + jx * charbox.height;
		for (GlkStyledString *str in sln.arr) {
			pt.x = marginoffset.x + str.pos * charbox.width;
			[str.str drawAtPoint:pt withFont:fonts[str.style]];
		}
		jx++;
	}
}

- (void) updateFromWindowState {
	GlkWindowGrid *gridwin = (GlkWindowGrid *)win;
	BOOL anychanges = NO;
	
	int height = gridwin.height;
	for (int jx=0; jx<gridwin.lines.count; jx++) {
		GlkGridLine *ln = [gridwin.lines objectAtIndex:jx];
		BOOL wasdirty = ln.dirty;
		ln.dirty = NO;
		if (jx < lines.count && !wasdirty)
			continue;
		
		GlkStyledLine *sln = [[GlkStyledLine alloc] init];
		if (jx < lines.count)
			[lines replaceObjectAtIndex:jx withObject:sln];
		else
			[lines addObject:sln];
		[sln release];
		anychanges = YES;
		
		NSMutableArray *arr = sln.arr;
		glui32 cursty;
		int ix = 0;
		while (ix < ln.width) {
			int pos = ix;
			cursty = ln.styles[pos];
			while (ix < ln.width && ln.styles[ix] == cursty)
				ix++;
			NSString *str = [[NSString alloc] initWithBytes:&ln.chars[pos] length:(ix-pos)*sizeof(glui32) encoding:NSUTF32LittleEndianStringEncoding];
			GlkStyledString *span = [[GlkStyledString alloc] initWithText:str style:cursty];
			span.pos = pos;
			[arr addObject:span];
			[span release];
		}
	}
	
	while (lines.count > height) {
		[lines removeLastObject];
		anychanges = YES;
	}
	
	if (!anychanges)
		return;
	
	[self setNeedsDisplay];
}

- (void) placeInputField:(UITextField *)field {
	GlkWindowGrid *gridwin = (GlkWindowGrid *)win;
	
	CGSize charbox = styleset.charbox;
	CGPoint marginoffset = styleset.marginframe.origin;
	CGRect box;
	
	box.origin.x = marginoffset.x + gridwin.curx * charbox.width;
	if (box.origin.x >= self.bounds.size.width * 0.75)
		box.origin.x = self.bounds.size.width * 0.75;
	box.size.width = self.bounds.size.width - box.origin.x;
	box.origin.y = marginoffset.y + gridwin.cury * charbox.height;
	box.size.height = 24;
	if (box.origin.y + box.size.height > self.bounds.size.height)
		box.origin.y = self.bounds.size.height - box.size.height;
		
	field.frame = box;
	if (!field.superview)
		[self addSubview:field];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	//### totally bogus, testing only
	/*
	UITouch *touch = [[event touchesForView:self] anyObject];
	CGPoint loc = [touch locationInView:self];
	[[GlkAppWrapper singleton] acceptEventType:99 window:win val1:loc.x val2:loc.y];
	*/
	
	[[IosGlkAppDelegate singleton].viewController hideKeyboard];
	
}

@end

