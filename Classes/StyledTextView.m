/* StyledTextView.m: Rich text view class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "StyledTextView.h"
#import "GlkUtilTypes.h"

#include "GlkUtilities.h"

@implementation StyledTextView

@synthesize lines;
@synthesize vlines;

static NSArray *fontArray; // retained forever
static CGFloat normalpointsize;

+ (void) initialize {
	CGFloat fontsize = 14.0;
	//### get this from somewhere
	fontArray = [NSArray arrayWithObjects: 
		[UIFont fontWithName:@"HelveticaNeue" size:fontsize],
		[UIFont fontWithName:@"HelveticaNeue-Italic" size:fontsize],
		[UIFont fontWithName:@"HelveticaNeue" size:fontsize],
		[UIFont fontWithName:@"HelveticaNeue-Bold" size:fontsize],
		[UIFont fontWithName:@"HelveticaNeue-Bold" size:fontsize],
		[UIFont fontWithName:@"HelveticaNeue" size:fontsize],
		[UIFont fontWithName:@"HelveticaNeue" size:fontsize],
		[UIFont fontWithName:@"HelveticaNeue" size:fontsize],
		[UIFont fontWithName:@"HelveticaNeue" size:fontsize],
		[UIFont fontWithName:@"HelveticaNeue" size:fontsize],
		[UIFont fontWithName:@"HelveticaNeue" size:fontsize],
		nil];
	[fontArray retain];
	
	UIFont *normalfont = [fontArray objectAtIndex:style_Normal];
	normalpointsize = normalfont.pointSize;
}

- (id) initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		wrapwidth = self.bounds.size.width;
		self.lines = [NSMutableArray arrayWithCapacity:32];
		self.vlines = [NSMutableArray arrayWithCapacity:32];
	}
	return self;
}

- (void) dealloc {
	self.lines = 0;
	self.vlines = 0;
	[super dealloc];
}

- (CGFloat) totalHeight {
	if (!vlines || !vlines.count)
		return 0.0;
	GlkVisualLine *vln = [vlines lastObject];
	return vln.ypos + vln.height;
}

/* Add the given lines to the contents. */
- (void) updateWithLines:(NSArray *)addlines {
	NSLog(@"STV: updating, adding %d lines", addlines.count);
	int lineslaidout = lines.count;
	
	/* First, add the data to the raw (unformatted) lines array. This may include clear operations, although hopefully only one per invocation. */
	for (GlkStyledLine *sln in addlines) {
		if (sln.status == linestat_ClearPage) {
			[lines removeAllObjects];
			[vlines removeAllObjects];
			lineslaidout = 0;
		}
		
		if (sln.status == linestat_Continue && lines.count > 0) {
			if (lineslaidout > (lines.count - 1))
				lineslaidout = (lines.count - 1);
			GlkStyledLine *prevln = [lines lastObject];
			[prevln.arr addObjectsFromArray:sln.arr];
		}
		else {
			[lines addObject:sln];
		}
	}
	
	/* Now do a layout operation, starting with the first line that changed. */
	[self layoutFromLine:lineslaidout];
}

- (void) layoutFromLine:(int)fromline {
	if (wrapwidth <= 5.0) {
		/* This isn't going to work out. */
		NSLog(@"STV: too narrow; refusing layout.");
		[vlines removeAllObjects];
		return;
	}
	
	if (fromline == 0) {
		NSLog(@"STV: discarding all vlines...");
		[vlines removeAllObjects];
	}
	else {
		int vcount = vlines.count;
		for (vcount = vlines.count; vcount; vcount--) {
			GlkVisualLine *vln = [vlines objectAtIndex:vcount-1];
			if (vln.linenum < fromline)
				break;
		}
		if (vcount < vlines.count) {
			NSRange range;
			range.location = vcount;
			range.length = vlines.count - vcount;
			NSLog(@"STV: discarding %d vlines (starting at %d)...", range.length, range.location);
			[vlines removeObjectsInRange:range];
		}
	}
	
	CGFloat ypos = [self totalHeight];
	
	for (int snum = fromline; snum < lines.count; snum++) {
		GlkStyledLine *sln = [lines objectAtIndex:snum];
		GlkVisualLine *vln = [[[GlkVisualLine alloc] init] autorelease];
		[vlines addObject:vln];
		vln.ypos = ypos;
		
		CGFloat hpos = 0.0;
		CGFloat maxheight = normalpointsize;
		CGFloat maxascender = 0.0;
		CGFloat maxdescender = 0.0;
		for (GlkStyledString *sstr in sln.arr) {
			NSString *str = sstr.str;
			UIFont *font = [fontArray objectAtIndex:sstr.style];
			int strlen = str.length;
			int wdpos = 0;
			while (wdpos < strlen) {
				/* A "word" in this wrapping algorithm is whitespace followed by blackspace. */
				int wdend = wdpos;
				while (wdend < strlen) {
					if ([str characterAtIndex:wdend] != ' ')
						break;
					wdend++;
				}
				while (wdend < strlen) {
					if ([str characterAtIndex:wdend] == ' ')
						break;
					wdend++;
				}
				
				NSRange range;
				range.location = wdpos;
				range.length = wdend - wdpos;
				NSString *wdtext = [str substringWithRange:range];
				CGSize wordsize = [wdtext sizeWithFont:font];
				
				/* We have to wrap if this word will overflow the line. But if this is the first word on the line (which must be a very long word), we don't wrap here -- that would just waste a line. */
				if (vln.arr.count > 0 && hpos+wordsize.width > wrapwidth) {
					vln.height = maxheight;
					ypos += maxheight;
					
					vln = [[[GlkVisualLine alloc] init] autorelease];
					[vlines addObject:vln];
					vln.ypos = ypos;

					hpos = 0.0;
					maxheight = normalpointsize;
					maxascender = 0.0;
					maxdescender = 0.0;
				}
				
				/* If the word still overflows, we (inefficiently) look for a place to break it up. */
				if (hpos+wordsize.width > wrapwidth) {
					while (range.length > 1) {
						range.length--;
						wdtext = [str substringWithRange:range];
						wordsize = [wdtext sizeWithFont:font];
						if (hpos+wordsize.width <= wrapwidth)
							break;
					}
					wdend = wdpos + range.length;
				}
				
				GlkVisualString *vwd = [[GlkVisualString alloc] initWithText:wdtext style:sstr.style];
				[vln.arr addObject:vwd];
				[vwd release];
				
				hpos += wordsize.width;
				if (maxheight < wordsize.height)
					maxheight = wordsize.height;
				if (maxascender < font.ascender)
					maxascender = font.ascender;
				if (maxdescender > font.descender)
					maxdescender = font.descender;
					
				wdpos = wdend;
			}
		}
		
		vln.height = maxheight;
		ypos += maxheight;
	}
	
	NSLog(@"STV: laid out %d vislines, wrapwidth %.1f, totalheight %.1f", vlines.count, wrapwidth, [self totalHeight]);
}

- (void) drawRect:(CGRect)rect {
	NSLog(@"StyledTextView: drawRect");
	CGContextRef gc = UIGraphicsGetCurrentContext();
	CGContextSetRGBFillColor(gc,  1, 1, 1,  1);
	CGContextFillRect(gc, rect);

	CGContextSetRGBFillColor(gc,  0, 0, 0,  1);
	
	for (GlkVisualLine *vln in vlines) {
		//### skip if not in bbox!
		CGPoint pt;
		pt.y = vln.ypos;
		pt.x = 0.0;
		for (GlkVisualString *vwd in vln.arr) {
			UIFont *font = [fontArray objectAtIndex:vwd.style];
			CGSize wordsize = [vwd.str drawAtPoint:pt withFont:font];
			pt.x += wordsize.width;
		}
	}
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	//NSLog(@"STV: Touch began");
}

@end
