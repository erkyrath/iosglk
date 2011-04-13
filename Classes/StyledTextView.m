/* StyledTextView.m: Rich text view class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "StyledTextView.h"
#import "GlkUtilTypes.h"
#import "StyleSet.h"
#import "GlkUtilities.h"

@implementation StyledTextView

@synthesize lines;
@synthesize vlines;
@synthesize styleset;

- (id) initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		wrapwidth = self.bounds.size.width;
		self.lines = [NSMutableArray arrayWithCapacity:32];
		self.vlines = [NSMutableArray arrayWithCapacity:32];
		styleset = nil;
		
		/* We don't try set the contentMode, because this thing isn't really capable of smart resizing-with-partial-redrawing. Instead, both of the paths that resize the view (updateFromWindowState and layoutSubviews) cause a complete redraw. */
		//self.contentMode = UIViewContentModeRedraw;
	}
	return self;
}

- (void) dealloc {
	self.lines = nil;
	self.vlines = nil;
	self.styleset = nil;
	[super dealloc];
}

- (void) setTotalWidth:(CGFloat)val {
	if (totalwidth == val)
		return;
		
	NSLog(@"STV: setTotalWidth %.01f", val);
	totalwidth = val;
	wrapwidth = val - styleset.marginframe.size.width;
	[self layoutFromLine:0];
}

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
	return [self textHeight] + styleset.marginframe.size.height;
}

/* Add the given lines (as taken from the GlkWindowBuffer) to the contents of the view. 
*/
- (void) updateWithLines:(NSArray *)addlines {
	//NSLog(@"STV: updating, adding %d lines", addlines.count);
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

/* Do the work of laying out the text. Start with line number fromline (in the lines array). All vlines from that point on are discarded and re-laid-out.
*/
- (void) layoutFromLine:(int)fromline {
	if (wrapwidth <= styleset.charbox.width) {
		/* This isn't going to work out. */
		//NSLog(@"STV: too narrow; refusing layout.");
		[vlines removeAllObjects];
		return;
	}
	
	if (vlines.count == 0) {
		/* nothing to discard. */
	}
	else if (fromline == 0) {
		//NSLog(@"STV: discarding all %d vlines...", vlines.count);
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
			//NSLog(@"STV: discarding %d vlines (starting at %d)...", range.length, range.location);
			[vlines removeObjectsInRange:range];
		}
	}
	
	UIFont **fonts = styleset.fonts;
	CGFloat normalpointsize = styleset.charbox.height;
	
	CGFloat ypos = styleset.marginframe.origin.y + [self textHeight];
	
	for (int snum = fromline; snum < lines.count; snum++) {
		GlkStyledLine *sln = [lines objectAtIndex:snum];
		
		int spannum = -1;
		GlkStyledString *sstr = nil;
		NSString *str;
		UIFont *sfont;
		int wdpos;
		int strlen;

		BOOL paragraphdone = NO;
		
		while (!paragraphdone) {
			GlkVisualLine *vln = [[[GlkVisualLine alloc] init] autorelease];
			[vlines addObject:vln];
			vln.ypos = ypos;
			vln.linenum = snum;
			
			CGFloat hpos = 0.0;
			CGFloat maxheight = normalpointsize;
			CGFloat maxascender = 0.0;
			CGFloat maxdescender = 0.0;
			BOOL linedone = NO;
			
			while (!linedone) {
				if (!sstr) {
					spannum++;
					if (spannum >= sln.arr.count) {
						linedone = YES;
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
					if (vln.arr.count > 0 && hpos+wordsize.width > wrapwidth) {
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
					[vln.arr addObject:vwd];
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
			
			vln.height = maxheight;
			ypos += maxheight;
		}
	}
		
	//NSLog(@"STV: laid out %d vislines, wrapwidth %.1f, textheight %.1f", vlines.count, wrapwidth, [self textHeight]);
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
		CGFloat ptx = styleset.marginframe.origin.x;
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

- (void) drawRect:(CGRect)rect {
	//NSLog(@"StyledTextView: drawRect %@ (bounds are %@)", StringFromRect(rect), StringFromRect(self.bounds));
	CGContextRef gc = UIGraphicsGetCurrentContext();
	CGContextSetRGBFillColor(gc,  1, 1, 1,  1);
	CGContextFillRect(gc, rect);

	CGContextSetRGBFillColor(gc,  0, 0, 0,  1);
	
	CGFloat rectminy = rect.origin.y;
	CGFloat rectmaxy = rect.origin.y+rect.size.height;
	
	UIFont **fonts = styleset.fonts;
	
	for (GlkVisualLine *vln in vlines) {
		if (vln.ypos+vln.height < rectminy || vln.ypos > rectmaxy)
			continue;
		CGPoint pt;
		pt.y = vln.ypos;
		pt.x = styleset.marginframe.origin.x;
		for (GlkVisualString *vwd in vln.arr) {
			UIFont *font = fonts[vwd.style];
			CGSize wordsize = [vwd.str drawAtPoint:pt withFont:font];
			pt.x += wordsize.width;
		}
	}
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	//NSLog(@"STV: Touch began");
}

@end
