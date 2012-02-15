/* StyledTextView.m: Rich text view class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "StyledTextView.h"
#import "GlkUtilTypes.h"
#import "StyleSet.h"
#import "GlkUtilities.h"

#define LAYOUT_HEADROOM (100)
#define STRIPE_WIDTH (100)

@implementation StyledTextView

@synthesize lines;
@synthesize vlines;
@synthesize linesviews;
@synthesize styleset;

- (id) initWithFrame:(CGRect)frame styles:(StyleSet *)stylesval {
	self = [super initWithFrame:frame];
	if (self) {
		self.lines = [NSMutableArray arrayWithCapacity:32];
		self.vlines = [NSMutableArray arrayWithCapacity:32];
		self.linesviews = [NSMutableArray arrayWithCapacity:32];
		self.styleset = stylesval;

		totalwidth = self.bounds.size.width;
		wrapwidth = totalwidth - styleset.margintotal.width;

		self.alwaysBounceVertical = YES;
		self.contentSize = self.bounds.size;
		self.backgroundColor = styleset.backgroundcolor;
	}
	return self;
}

- (void) dealloc {
	self.lines = nil;
	self.vlines = nil;
	self.linesviews = nil;
	self.styleset = nil;
	[super dealloc];
}

/* The total height of the window, including rendered text and margins. 
*/
- (CGFloat) totalHeight {
	if (!vlines || !vlines.count)
		return styleset.margins.top + styleset.margins.bottom;
	GlkVisualLine *vln = [vlines lastObject];
	return vln.bottom + styleset.margins.bottom;
}

/* Add the given lines (as taken from the GlkWindowBuffer) to the contents of the view. 
*/
- (void) updateWithLines:(NSArray *)addlines {
	NSLog(@"STV: updating, adding %d lines", addlines.count);
	
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
	
	/* Now trash all the VisualLinesViews. We'll create new ones at the next layout call. */
	NSLog(@"### removing all linesviews (for update)");
	//### Or only trash the ones that have been invalidated?
	for (VisualLinesView *linev in linesviews) {
		[linev removeFromSuperview];
	}
	[linesviews removeAllObjects];
}

- (void) layoutSubviews {
	[super layoutSubviews];
	
	CGRect visbounds = self.bounds;
	CGFloat visbottom = visbounds.origin.y + visbounds.size.height;
	//NSLog(@"STV: layoutSubviews to visbottom %.1f (%@)", visbottom, StringFromRect(self.bounds));
	
	CGFloat newtotal = visbounds.size.width;
	CGFloat newwrap = newtotal - styleset.margintotal.width;
	if (totalwidth != newtotal || wrapwidth != newwrap) {
		totalwidth = newtotal;
		wrapwidth = newwrap;
		NSLog(@"STV: width has changed! now %.01f (wrap %.01f)", totalwidth, wrapwidth);
		
		/* Trash all laid-out lines and VisualLinesViews. */
		NSLog(@"### removing all linesviews (for width change)");
		[vlines removeAllObjects];
		for (VisualLinesView *linev in linesviews) {
			[linev removeFromSuperview];
		}
		[linesviews removeAllObjects];
	}
	
	/* Extend vlines down until it's past the bottom of visbounds. (Or we're out of lines.) */
	//### This should be smart enough to no-op if vlines is empty but we're near the bottom.
	
	CGFloat bottom = styleset.margins.top;
	int endlaid = 0;
	if (vlines.count > 0) {
		GlkVisualLine *vln = [vlines lastObject];
		bottom = vln.bottom;
		endlaid = vln.linenum+1;
	}
	
	NSMutableArray *newlines = [self layoutFromLine:endlaid forward:YES yStart:bottom yMax:visbottom+LAYOUT_HEADROOM];
	if (newlines && newlines.count) {
		int oldcount = vlines.count;
		int newcount = 0;
		for (GlkVisualLine *vln in newlines) {
			vln.vlinenum = oldcount+newcount;
			newcount++;
		}
		[vlines addObjectsFromArray:newlines];
		NSLog(@"STV: appended %d vlines; lines are laid to %d (of %d); yrange is %.1f to %.1f", newlines.count, ((GlkVisualLine *)[vlines lastObject]).linenum, lines.count, ((GlkVisualLine *)[vlines objectAtIndex:0]).ypos, ((GlkVisualLine *)[vlines lastObject]).bottom);
	}
	
	/* Extend vlines up, similarly. */
	//### Similarly, this should run from the end if we're empty.
	
	CGFloat top = styleset.margins.top;
	int startlaid = 0;
	if (vlines.count > 0) {
		GlkVisualLine *vln = [vlines objectAtIndex:0];
		top = vln.ypos;
		startlaid = vln.linenum;
	}
	
	newlines = [self layoutFromLine:startlaid-1 forward:NO yStart:top yMax:visbounds.origin.y-LAYOUT_HEADROOM];
	if (newlines && newlines.count) {
		int newcount = 0;
		for (GlkVisualLine *vln in newlines) {
			vln.vlinenum = newcount;
			newcount++;
		}
		
		//### piecewise-reverse newlines!
		
		/* We're inserting at the beginning of the vlines array, so the existing vlines all shift downwards. */
		GlkVisualLine *lastvln = [newlines lastObject];
		CGFloat offset = lastvln.bottom - styleset.margins.top;
		for (GlkVisualLine *vln in vlines) {
			vln.vlinenum += newcount;
			vln.ypos += offset;
		}
		for (VisualLinesView *linev in linesviews) {
			linev.vlinestart += newcount;
			linev.vlineend += newcount;
		}

		NSRange range = {0,0};
		[vlines replaceObjectsInRange:range withObjectsFromArray:newlines];
		NSLog(@"STV: prepended %d vlines; lines are laid to %d (of %d); yrange is %.1f to %.1f", newlines.count, ((GlkVisualLine *)[vlines lastObject]).linenum, lines.count, ((GlkVisualLine *)[vlines objectAtIndex:0]).ypos, ((GlkVisualLine *)[vlines lastObject]).bottom);
	}
	
	/* Adjust the contentSize to match newly-created vlines. */
	//### if vlines were added on top, this should adjust contentOffset as well!
	
	CGFloat contentheight = self.totalHeight;
	
	if (self.contentSize.height != contentheight) {
		self.contentSize = CGSizeMake(visbounds.size.width, contentheight);
		/* Recompute the visual bounds. */
		visbounds = self.bounds;
		visbottom = visbounds.origin.y + visbounds.size.height;
	}
	
	/* Now, adjust the bottom of linesviews up or down (deleting or adding VisualLinesViews) until it reaches the bottom of visbounds. */
	//### again, smarten for ending
	
	endlaid = 0;
	bottom = 0;
	while (linesviews.count) {
		VisualLinesView *linev = [linesviews lastObject];
		if (linev.ytop < visbottom) {
			endlaid = linev.vlineend;
			bottom = linev.ybottom;
			break;
		}
		NSLog(@"### removing last lineview (%d), yrange is %.1f-%.1f", linesviews.count-1, linev.ytop, linev.ybottom);
		[linev removeFromSuperview];
		[linesviews removeLastObject];
	}
	
	while (bottom < visbottom && endlaid < vlines.count) {
		int newend = endlaid;
		CGFloat newbottom = bottom;
		while (newbottom < bottom+STRIPE_WIDTH && newend < vlines.count) {
			GlkVisualLine *vln = [vlines objectAtIndex:newend];
			newend++;
			newbottom = vln.bottom;
		}
		
		if (newend > endlaid) {
			NSRange range;
			range.location = endlaid;
			range.length = newend - endlaid;
			NSArray *subarr = [vlines subarrayWithRange:range];
			VisualLinesView *linev = [[[VisualLinesView alloc] initWithFrame:CGRectZero styles:styleset vlines:subarr] autorelease];
			linev.frame = CGRectMake(visbounds.origin.x, linev.ytop, visbounds.size.width, linev.height);
			[linesviews addObject:linev];
			[self insertSubview:linev atIndex:0];
			NSLog(@"### appending lineview (%d), yrange is %.1f-%.1f", linesviews.count-1, linev.ytop, linev.ybottom);
		}
		
		endlaid = newend;
		bottom = newbottom;
	}
	
	/* Similarly, adjust the top of linesviews up or down. */
	
	startlaid = 0;
	top = 0;
	while (linesviews.count) {
		VisualLinesView *linev = [linesviews objectAtIndex:0];
		if (linev.ybottom >= visbounds.origin.y) {
			startlaid = linev.vlinestart;
			top = linev.ytop;
			break;
		}
		NSLog(@"### removing first lineview, yrange is %.1f-%.1f", linev.ytop, linev.ybottom);
		[linev removeFromSuperview];
		[linesviews removeObjectAtIndex:0];
	}
	
	while (top > visbounds.origin.y && startlaid > 0) {
		int newstart = startlaid;
		CGFloat newtop = top;
		while (newtop > top-STRIPE_WIDTH && newstart > 0) {
			newstart--;
			GlkVisualLine *vln = [vlines objectAtIndex:newstart];
			newtop = vln.ypos;
		}
		
		if (newstart < startlaid) {
			NSRange range;
			range.location = newstart;
			range.length = startlaid - newstart;
			NSArray *subarr = [vlines subarrayWithRange:range];
			VisualLinesView *linev = [[[VisualLinesView alloc] initWithFrame:CGRectZero styles:styleset vlines:subarr] autorelease];
			linev.frame = CGRectMake(visbounds.origin.x, linev.ytop, visbounds.size.width, linev.height);
			[linesviews insertObject:linev atIndex:0];
			[self insertSubview:linev atIndex:0];
			NSLog(@"### prepending lineview, yrange is %.1f-%.1f", linev.ytop, linev.ybottom);
		}
		
		startlaid = newstart;
		top = newtop;
	}
	
	[self sanityCheck]; //###
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
			// vln.vlinesnum will be filled in by the caller.
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

- (void) sanityCheck {
	/*
	NSLog(@"### STV sanity check:");
	NSLog(@"   %d vlines:", vlines.count);
	for (GlkVisualLine *vln in vlines) {
		NSLog(@"    %d (raw %d): %.1f to %.1f, height %.1f", vln.vlinenum, vln.linenum, vln.ypos, vln.bottom, vln.height);
	}
	 */
	
	int count = 0;
	int lastraw = -1;
	CGFloat bottom = styleset.margins.top;
	for (GlkVisualLine *vln in vlines) {
		if (vln.vlinenum != count)
			NSLog(@"STV-SANITY: vlinenum %d is not %d", vln.vlinenum, count);
		if (vln.linenum != lastraw && vln.linenum != lastraw+1)
			NSLog(@"STV-SANITY: linenum %d is not %d or +1", vln.linenum, lastraw);
		if (vln.ypos != bottom)
			NSLog(@"STV-SANITY: ypos %.1f is not %.1f", vln.ypos, bottom);
		bottom = vln.bottom;
		lastraw = vln.linenum;
		count++;
	}
	
	count = 0;
	for (UIView *subview in self.subviews) {
		if ([subview isKindOfClass:[VisualLinesView class]])
			count++;
	}
	
	if (count != linesviews.count)
		NSLog(@"STV-SANITY: wrong number of subviews (%d, not %d)", count, linesviews.count);
	
	if (linesviews.count > 0) {
		VisualLinesView *firstlinev = [linesviews objectAtIndex:0];
		int lastv = firstlinev.vlinestart;
		bottom = firstlinev.ytop;
		
		for (VisualLinesView *linev in linesviews) {
			if (linev.vlines.count == 0)
				NSLog(@"STV-SANITY: linev has no lines");
			if (linev.vlines.count != linev.vlineend - linev.vlinestart)
				NSLog(@"STV-SANITY: linev count %d is not %d", linev.vlines.count, linev.vlineend - linev.vlinestart);
			if (linev.vlinestart != lastv)
				NSLog(@"STV-SANITY: vlinestart %d is not %d", linev.vlinestart, lastv);
			if (linev.vlinestart != (((GlkVisualLine *)([linev.vlines objectAtIndex:0])).vlinenum))
				NSLog(@"STV-SANITY: vlinestart %d does not match first vline", linev.vlinestart);
			if (linev.vlineend != (((GlkVisualLine *)([linev.vlines lastObject])).vlinenum) + 1)
				NSLog(@"STV-SANITY: vlineend %d does not match end vline", linev.vlineend);
			if (linev.ytop != bottom)
				NSLog(@"STV-SANITY: vlinestart %.1f is not %.1f", linev.ytop, bottom);
			lastv = linev.vlineend;
			bottom = linev.ybottom;
		}
	}
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	//NSLog(@"STV: Touch began");
}

@end


@implementation VisualLinesView

@synthesize vlines;
@synthesize styleset;
@synthesize ytop;
@synthesize ybottom;
@synthesize height;
@synthesize vlinestart;
@synthesize vlineend;

- (id) initWithFrame:(CGRect)frame styles:(StyleSet *)stylesval vlines:(NSArray *)arr {
	self = [super initWithFrame:frame];
	if (self) {
		self.vlines = arr;
		self.styleset = stylesval;
		
		//###self.backgroundColor = styleset.backgroundcolor;
		self.backgroundColor = [UIColor colorWithRed:(random()%127+128)/256.0 green:(random()%127+128)/256.0 blue:1 alpha:1]; //###
		self.userInteractionEnabled = NO;
		
		if (vlines.count > 0) {
			GlkVisualLine *vln = [vlines objectAtIndex:0];
			vlinestart = vln.vlinenum;
			ytop = vln.ypos;
			
			vln = [vlines lastObject];
			vlineend = vln.vlinenum+1;
			ybottom = vln.bottom;
			height = ybottom - ytop;
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
		pt.y = vln.ypos - ytop;
		pt.x = styleset.margins.left;
		for (GlkVisualString *vwd in vln.arr) {
			UIFont *font = fonts[vwd.style];
			CGSize wordsize = [vwd.str drawAtPoint:pt withFont:font];
			pt.x += wordsize.width;
		}
	}
}

@end


