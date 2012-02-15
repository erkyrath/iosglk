/* StyledTextView.m: Rich text view class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "StyledTextView.h"
#import "GlkUtilTypes.h"
#import "StyleSet.h"
#import "GlkUtilities.h"

#define LAYOUT_HEADROOM (0)

@implementation StyledTextView

@synthesize lines;
@synthesize vlines;
@synthesize styleset;

- (id) initWithFrame:(CGRect)frame styles:(StyleSet *)stylesval {
	self = [super initWithFrame:frame];
	if (self) {
		self.lines = [NSMutableArray arrayWithCapacity:32];
		self.vlines = [NSMutableArray arrayWithCapacity:32];
		self.styleset = stylesval;

		totalwidth = self.bounds.size.width;
		wrapwidth = totalwidth - styleset.margintotal.width;

		self.alwaysBounceVertical = YES;
		self.contentSize = self.bounds.size;
		//self.backgroundColor = styleset.backgroundcolor;
	}
	return self;
}

- (void) dealloc {
	self.lines = nil;
	self.vlines = nil;
	self.styleset = nil;
	[super dealloc];
}

/*###
- (void) setTotalWidth:(CGFloat)val {
	CGFloat newwrap = val - styleset.margintotal.width;
	if (totalwidth == val && wrapwidth == newwrap)
		return;
		
	NSLog(@"STV: setTotalWidth %.01f", val);
	totalwidth = val;
	wrapwidth = newwrap;
	//###[self layoutFromLine:0];
}
 ###*/

/* The total height of rendered text in the window (excluding margins). 
*/
- (CGFloat) textHeight {
	if (!vlines || !vlines.count)
		return 0.0;
	GlkVisualLine *vln = [vlines lastObject];
	return vln.ypos + vln.height;
}

/* The total height of the window, including rendered text and margins. 
*/
- (CGFloat) totalHeight {
	return [self textHeight] + styleset.margintotal.height;
}

/* Add the given lines (as taken from the GlkWindowBuffer) to the contents of the view. 
*/
- (void) updateWithLines:(NSArray *)addlines {
	//NSLog(@"STV: updating, adding %d lines", addlines.count);
	
	/* First, add the data to the raw (unformatted) lines array. This may include clear operations, although hopefully only one per invocation. */
	for (GlkStyledLine *sln in addlines) {
		if (sln.status == linestat_ClearPage) {
			[lines removeAllObjects];
			[vlines removeAllObjects];
			/* A ClearPage line can contain text as well, so we continue. */
		}
		
		if (sln.status == linestat_Continue && lines.count > 0) {
			GlkStyledLine *prevln = [lines lastObject];
			[prevln.arr addObjectsFromArray:sln.arr];
			/* The vlines corresponding to this line are no longer valid. Remove them. */
			int prevlnindex = lines.count-1;
			while (vlines.count > 0) {
				GlkVisualLine *vln = [vlines lastObject];
				if (vln.linenum < prevlnindex)
					break;
				[vlines removeLastObject];
			}
		}
		else {
			[lines addObject:sln];
		}
	}
	
	/* Now do a layout operation, starting with the first line that changed. */
	//###[self layoutFromLine:lineslaidout];
	
	//### trash all VisualLinesView objects. Or only ones that have been invalidated?
}

- (void) layoutSubviews {
	[super layoutSubviews];
	NSLog(@"STV: layoutSubviews to %@", StringFromRect(self.bounds));
	
	CGRect visbounds = self.bounds;
	CGFloat visbottom = visbounds.origin.y + visbounds.size.height;
	
	CGFloat newtotal = visbounds.size.width;
	CGFloat newwrap = newtotal - styleset.margintotal.width;
	if (totalwidth != newtotal || wrapwidth != newwrap) {
		totalwidth = newtotal;
		wrapwidth = newwrap;
		NSLog(@"STV: width has changed! now %.01f (wrap %.01f)", totalwidth, wrapwidth);
		
		[vlines removeAllObjects];
	}
	
	/* Extend vlines down until it's past the bottom of visbounds. (Or we're out of lines.) */
	
	CGFloat bottom = styleset.margins.top;
	int endlaid = 0;
	if (vlines.count > 0) {
		GlkVisualLine *vln = [vlines lastObject];
		bottom = vln.bottom;
		endlaid = vln.linenum+1;
	}
	
	NSMutableArray *newlines = [self layoutFromLine:endlaid forward:YES yStart:bottom yMax:visbottom+LAYOUT_HEADROOM];
	if (newlines && newlines.count) {
		[vlines addObjectsFromArray:newlines];
		NSLog(@"STV: appended %d vlines; lines are laid to %d (of %d); yrange is %.1f to %.1f", newlines.count, ((GlkVisualLine *)[vlines lastObject]).linenum, lines.count, ((GlkVisualLine *)[vlines objectAtIndex:0]).ypos, ((GlkVisualLine *)[vlines lastObject]).bottom);
	}
	
	CGFloat top = styleset.margins.top;
	int startlaid = 0;
	if (vlines.count > 0) {
		GlkVisualLine *vln = [vlines objectAtIndex:0];
		top = vln.ypos;
		startlaid = vln.linenum;
	}
	
	newlines = [self layoutFromLine:startlaid-1 forward:NO yStart:top yMax:visbounds.origin.y-LAYOUT_HEADROOM];
	if (newlines && newlines.count) {
		//### piecewise-reverse newlines!
		
		/* We're inserting at the beginning of the vlines array, so the existing vlines all shift downwards. */
		GlkVisualLine *lastvln = [newlines lastObject];
		CGFloat offset = lastvln.bottom - styleset.margins.top;
		int newcount = newlines.count;
		for (GlkVisualLine *vln in vlines) {
			vln.linenum += newcount;
			vln.ypos += offset;
		}
		
		NSRange range = {0,0};
		[vlines replaceObjectsInRange:range withObjectsFromArray:newlines];
		NSLog(@"STV: prepended %d vlines; lines are laid to %d (of %d); yrange is %.1f to %.1f", newlines.count, ((GlkVisualLine *)[vlines lastObject]).linenum, lines.count, ((GlkVisualLine *)[vlines objectAtIndex:0]).ypos, ((GlkVisualLine *)[vlines lastObject]).bottom);
	}
}

/* Do the work of laying out the text. Start with line number startline (in the lines array); continue until the yposition reaches ymax or the lines run out. Return a temporary array containing the new lines.
*/
- (NSMutableArray *) layoutFromLine:(int)startline forward:(BOOL)forward yStart:(CGFloat)ystart yMax:(CGFloat)ymax {
	if (wrapwidth <= 4*styleset.charbox.width) {
		/* This isn't going to work out. */
		//NSLog(@"STV: too narrow; refusing layout.");
		return nil;
	}
	
	int loopincrement;
	
	/* If the loop won't run, we'll save ourselves the effort. */
	if (forward) {
		loopincrement = 1;
		if (startline >= lines.count || ystart >= ymax)
			return nil;
	}
	else {
		loopincrement = -1;
		if (startline < 0 || ystart < ymax)
			return nil;
	}
	
	UIFont **fonts = styleset.fonts;
	CGFloat normalpointsize = styleset.charbox.height;
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:32]; // vlines laid out
	NSMutableArray *tmparr = [NSMutableArray arrayWithCapacity:64]; // words in a line
	
	CGFloat ypos = ystart;
	
	for (int snum = startline; YES; snum += loopincrement) {
		if (forward) {
			if (snum >= lines.count || ypos >= ymax)
				break;
		}
		else {
			if (snum < 0 || ypos < ymax)
				break;
		}
		
		GlkStyledLine *sln = [lines objectAtIndex:snum];
		
		int spannum = -1;
		GlkStyledString *sstr = nil;
		NSString *str;
		UIFont *sfont;
		int wdpos;
		int strlen;

		BOOL paragraphdone = NO;
		
		while (!paragraphdone) {
			CGFloat hpos = 0.0;
			CGFloat maxheight = normalpointsize;
			CGFloat maxascender = 0.0;
			CGFloat maxdescender = 0.0;
			BOOL linedone = NO;
			
			while (!linedone) {
				if (!sstr) {
					spannum++;
					if (spannum >= sln.arr.count) {
						//linedone = YES;
						paragraphdone = YES;
						break;
					}
					sstr = [sln.arr objectAtIndex:spannum];
					str = sstr.str;
					sfont = fonts[sstr.style];
					strlen = str.length;
					wdpos = 0;
				}

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
					CGSize wordsize = [wdtext sizeWithFont:sfont];
					
					/* We want to wrap if this word will overflow the line. But if this is the first word on the line (which must be a very long word), we don't wrap here -- that would cause an infinite loop. */
					if (tmparr.count > 0 && hpos+wordsize.width > wrapwidth) {
						/* We don't advance wdpos to wdend, because we'll be re-measuring this word on the next line. However, we do want to squash out whitespace across the break -- the next line shouldn't start with a space. */
						while (wdpos < strlen) {
							if ([str characterAtIndex:wdpos] != ' ')
								break;
							wdpos++;
						}
						linedone = YES;
						break;
					}
					
					/* If the word still overflows, we (inefficiently) look for a place to break it up. */
					if (hpos+wordsize.width > wrapwidth) {
						while (range.length > 1) {
							range.length--;
							wdtext = [str substringWithRange:range];
							wordsize = [wdtext sizeWithFont:sfont];
							if (hpos+wordsize.width <= wrapwidth)
								break;
						}
						wdend = wdpos + range.length;
					}
					
					GlkVisualString *vwd = [[GlkVisualString alloc] initWithText:wdtext style:sstr.style];
					[tmparr addObject:vwd];
					[vwd release];
					
					hpos += wordsize.width;
					if (maxheight < wordsize.height)
						maxheight = wordsize.height;
					if (maxascender < sfont.ascender)
						maxascender = sfont.ascender;
					if (maxdescender > sfont.descender)
						maxdescender = sfont.descender;
						
					wdpos = wdend;
				}
				
				if (wdpos >= strlen) {
					sstr = nil;
				}
			}

			GlkVisualLine *vln = [[[GlkVisualLine alloc] initWithStrings:tmparr] autorelease];
			vln.ypos = ypos;
			vln.linenum = snum;
			vln.height = maxheight;
			ypos += maxheight;
			
			[result addObject:vln];
			[tmparr removeAllObjects];
		}
	}
		
	NSLog(@"STV: laid out %d vislines, final ypos %.1f (first line %d of %d)", result.count, ypos, startline, lines.count);
	return result;
}

- (CGRect) placeForInputField {
	CGRect box;
	UIFont **fonts = styleset.fonts;
	
	if (!vlines || !vlines.count) {
		box.origin.x = 0;
		box.size.width = totalwidth;
		box.origin.y = 0;
		box.size.height = 24;
	}
	else {
		GlkVisualLine *vln = [vlines lastObject];
		CGFloat ptx = styleset.margins.left;
		for (GlkVisualString *vwd in vln.arr) {
			UIFont *font = fonts[vwd.style];
			CGSize wordsize = [vwd.str sizeWithFont:font];
			ptx += wordsize.width;
		}
		
		if (ptx >= totalwidth * 0.75)
			ptx = totalwidth * 0.75;
		
		box.origin.x = ptx;
		box.size.width = totalwidth - ptx;
		box.origin.y = vln.ypos;
		box.size.height = 24;
	}
	
	//NSLog(@"placeForInputField: %@", StringFromRect(box));
	return box;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	//NSLog(@"STV: Touch began");
}

@end


@implementation VisualLinesView

@synthesize vlines;
@synthesize styleset;

- (id) initWithFrame:(CGRect)frame styles:(StyleSet *)stylesval vlines:(NSArray *)arr {
	self = [super initWithFrame:frame];
	if (self) {
		self.vlines = [NSArray arrayWithArray:arr];
		self.styleset = stylesval;
		
		self.backgroundColor = styleset.backgroundcolor;
		self.userInteractionEnabled = NO;
		
		if (vlines.count > 0) {
			GlkVisualLine *vln = [vlines objectAtIndex:0];
			yoffset = vln.ypos;
			
			vln = [vlines lastObject];
			height = vln.bottom;
		}
		else {
			yoffset = 0;
			height = 0;
		}
	}
	return self;
}

- (void) dealloc {
	self.vlines = nil;
	self.styleset = nil;
	[super dealloc];
}

- (void) drawRect:(CGRect)rect {
	//NSLog(@"StyledTextView: drawRect %@ (bounds are %@)", StringFromRect(rect), StringFromRect(self.bounds));
	CGContextRef gc = UIGraphicsGetCurrentContext();
	
	CGContextSetRGBFillColor(gc,  0, 0, 0,  1);
	
	UIFont **fonts = styleset.fonts;
	
	for (GlkVisualLine *vln in vlines) {
		CGPoint pt;
		pt.y = vln.ypos - yoffset;
		pt.x = styleset.margins.left;
		for (GlkVisualString *vwd in vln.arr) {
			UIFont *font = fonts[vwd.style];
			CGSize wordsize = [vwd.str drawAtPoint:pt withFont:font];
			pt.x += wordsize.width;
		}
	}
}

@end


