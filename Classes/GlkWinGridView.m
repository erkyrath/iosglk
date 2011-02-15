/* GlkWinGridView.m: Glk textgrid window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "GlkWinGridView.h"
#import "GlkWindow.h"
#import "GlkUtilTypes.h"


@implementation GlkWinGridView

@synthesize lines;

static NSArray *fontArray; // retained forever

+ (void) initialize {
	CGFloat fontsize = 14.0;
	//### get this from somewhere
	fontArray = [NSArray arrayWithObjects: 
		[UIFont fontWithName:@"Courier" size:fontsize],
		[UIFont fontWithName:@"Courier-Oblique" size:fontsize],
		[UIFont fontWithName:@"Courier" size:fontsize],
		[UIFont fontWithName:@"Courier-Bold" size:fontsize],
		[UIFont fontWithName:@"Courier-Bold" size:fontsize],
		[UIFont fontWithName:@"Courier" size:fontsize],
		[UIFont fontWithName:@"Courier" size:fontsize],
		[UIFont fontWithName:@"Courier" size:fontsize],
		[UIFont fontWithName:@"Courier" size:fontsize],
		[UIFont fontWithName:@"Courier" size:fontsize],
		[UIFont fontWithName:@"Courier" size:fontsize],
		nil];
	[fontArray retain];
}

- (id) initWithWindow:(GlkWindow *)winref frame:(CGRect)box {
	self = [super initWithWindow:winref frame:box];
	if (self) {
		self.lines = [NSMutableArray arrayWithCapacity:8];
	}
	return self;
}

- (void) dealloc {
	self.lines = nil;
	[super dealloc];
}

- (void) drawRect:(CGRect)rect {
	NSLog(@"GridView: drawRect");
	CGContextRef gc = UIGraphicsGetCurrentContext();
	CGContextSetRGBFillColor(gc,  1, 1, 1,  1);
	CGContextFillRect(gc, rect);
	
	CGContextSetRGBFillColor(gc,  0, 0, 0,  1);
	
	//### do some real font size calculation here.
	
	int jx = 0;
	for (GlkStyledLine *sln in lines) {
		CGPoint pt;
		pt.y = jx * 14.0;
		for (GlkStyledString *str in sln.arr) {
			pt.x = str.pos * 8.0;
			UIFont *font = [fontArray objectAtIndex:str.style];
			[str.str drawAtPoint:pt withFont:font];
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

@end

