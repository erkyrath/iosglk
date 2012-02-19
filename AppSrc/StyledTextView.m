/* StyledTextView.m: Rich text view class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "StyledTextView.h"
#import "GlkWinBufferView.h"
#import "CmdTextField.h"
#import "GlkUtilTypes.h"
#import "StyleSet.h"
#import "GlkUtilities.h"

#define LAYOUT_HEADROOM (1000)
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
		wasclear = YES;

		totalheight = self.bounds.size.height;
		totalwidth = self.bounds.size.width;
		wrapwidth = totalwidth - styleset.margintotal.width;

		self.alwaysBounceVertical = YES;
		self.contentSize = self.bounds.size;
		self.backgroundColor = styleset.backgroundcolor;
		
		taplastat = 0; // the past
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

- (GlkWinBufferView *) superviewAsBufferView {
	return (GlkWinBufferView *)self.superview;
}

/* Return the scroll position in the page, between 0.0 and 1.0. This is only an approximation, because we don't always have the whole page laid out (into vlines). If the page content is empty or shorter than its height, returns 0.
 */
- (CGFloat) scrollPercentage {
	CGSize contentsize = self.contentSize;
	CGSize vissize = self.bounds.size;
	if (contentsize.height <= vissize.height)
		return 0;
	CGFloat res = self.contentOffset.y / (contentsize.height - vissize.height);
	return res;
}

/* The total height of the window, including rendered text and margins. 
*/
- (CGFloat) totalHeight {
	if (!vlines || !vlines.count)
		return styleset.margins.top + styleset.margins.bottom;
	GlkVisualLine *vln = [vlines lastObject];
	return vln.bottom + styleset.margins.bottom;
}

/* The first raw line that exists in vlines (laid-out lines). Return -1 if vlines is empty.
 */
- (int) firstLaidOutLine {
	if (!vlines || !vlines.count)
		return -1;
	GlkVisualLine *vln = [vlines objectAtIndex:0];
	return vln.linenum;
}

/* The last raw line that exists in vlines, plus one. (That is, the first non-laid-out line. If this is equal to lines.count, layout extends all the way down.) Returns 0 if vlines is empty.
 */
- (int) lastLaidOutLine {
	if (!vlines || !vlines.count)
		return 0;
	GlkVisualLine *vln = [vlines lastObject];
	return vln.linenum + 1;
}

/* 
 ### also check (self.lastLaidOutLine < lines.count)?
 */
- (BOOL) moreToSee {
	BOOL mustpage = (endvlineseen < vlines.count);
	return mustpage;
}

- (GlkVisualLine *) lineAtPos:(CGFloat)ypos {
	if (!vlines || !vlines.count)
		return nil;
	CGFloat height = self.totalHeight;
	if (ypos >= height)
		return nil;
	if (height <= styleset.margins.top)
		return nil;
	
	CGFloat frac = (ypos-styleset.margins.top) / (height-styleset.margins.top);
	int pos = (vlines.count * frac);
	pos = MIN(vlines.count-1, pos);
	pos = MAX(pos, 0);
	
	while (pos > 0 && ypos < ((GlkVisualLine *)[vlines objectAtIndex:pos]).ypos) {
		pos--;
	}
	while (pos < vlines.count-1 && ypos >= ((GlkVisualLine *)[vlines objectAtIndex:pos+1]).ypos) {
		pos++;
	}
	
	return ((GlkVisualLine *)[vlines objectAtIndex:pos]);
}

- (CGRect) placeForInputField {
	CGRect box;
	
	if (!vlines || !vlines.count) {
		box.origin.x = styleset.margins.left;
		box.size.width = totalwidth - styleset.margintotal.width;
		box.origin.y = 0;
		box.size.height = 24;
		return box;
	}
	
	if (self.lastLaidOutLine < self.lines.count) {
		box.origin.x = styleset.margins.left;
		box.size.width = totalwidth - styleset.margintotal.width;
		box.origin.y = self.totalHeight;
		box.size.height = 24;
		return box;
	}
	
	GlkVisualLine *vln = [vlines lastObject];
	CGFloat ptx = vln.right;
	if (ptx >= totalwidth * 0.75)
		ptx = totalwidth * 0.75;
	
	box.origin.x = ptx;
	box.size.width = (totalwidth-styleset.margins.right) - ptx;
	box.origin.y = vln.ypos;
	box.size.height = vln.height;
	
	return box;
}

/* Add the given lines (as taken from the GlkWindowBuffer) to the contents of the view. 
*/
- (void) updateWithLines:(NSArray *)addlines {
	NSLog(@"STV: updating, adding %d lines", addlines.count);
	newcontent = YES;
	
	/* First, add the data to the raw (unformatted) lines array. This may include clear operations, although hopefully only one per invocation. */
	for (GlkStyledLine *sln in addlines) {
		if (sln.status == linestat_ClearPage) {
			[lines removeAllObjects];
			[vlines removeAllObjects];
			endvlineseen = 0;
			wasclear = YES;
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
			if (endvlineseen > vlines.count)
				endvlineseen = vlines.count;
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
		
	/* First step: check the page width. If it's changed, discard all layout and start over. (Changing the margins has the same effect.) */
	
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
		
		endvlineseen = 0;
	}
	
	/* If the page height has changed, we will want to do a vertical shift later on. (But if the width changed too, forget it -- that's a complete re-layout.)
	 
		(Also, if the view is expanding and we're at the bottom, the shift may already have been applied -- I guess when the frame changed. In that case, we leave heightchangeoffset at zero.) 
	 */
	CGFloat heightchangeoffset = 0;
	if (totalheight != visbounds.size.height) {
		if (vlines.count > 0 && self.contentOffset.y+visbounds.size.height < self.contentSize.height) {
			heightchangeoffset = totalheight - visbounds.size.height;
		}
		totalheight = visbounds.size.height;
	}
	
	/* Extend vlines down until it's past the bottom of visbounds. (Or we're out of lines.) 
	 
		Special case: if there are no vlines at all *and* we're near the bottom, we skip this step; we'll lay out from the bottom up rather than the top down. (If there are vlines, we always extend that range both ways.) 
	 */
	BOOL frombottom = (vlines.count == 0 && !wasclear && self.scrollPercentage > 0.5);
	
	CGFloat bottom = styleset.margins.top;
	int endlaid = 0;
	if (vlines.count > 0) {
		GlkVisualLine *vln = [vlines lastObject];
		bottom = vln.bottom;
		endlaid = vln.linenum+1;
	}
	
	NSMutableArray *newlines = nil;
	if (!frombottom)
		newlines = [self layoutFromLine:endlaid forward:YES yMax:(visbottom-bottom)+LAYOUT_HEADROOM];
	if (newlines && newlines.count) {
		int oldcount = vlines.count;
		int newcount = 0;
		for (GlkVisualLine *vln in newlines) {
			vln.vlinenum = oldcount+newcount;
			vln.ypos += bottom;
			newcount++;
		}
		[vlines addObjectsFromArray:newlines];
		NSLog(@"STV: appended %d vlines; lines are laid to %d (of %d); yrange is %.1f to %.1f", newlines.count, ((GlkVisualLine *)[vlines lastObject]).linenum, lines.count, ((GlkVisualLine *)[vlines objectAtIndex:0]).ypos, ((GlkVisualLine *)[vlines lastObject]).bottom);
	}
	
	/* Extend vlines up, similarly. */
	
	CGFloat upextension = 0;
	
	CGFloat top = visbottom;
	int startlaid = lines.count;
	if (vlines.count > 0) {
		GlkVisualLine *vln = [vlines objectAtIndex:0];
		top = vln.ypos;
		startlaid = vln.linenum;
	}
	
	newlines = [self layoutFromLine:startlaid-1 forward:NO yMax:(top-visbounds.origin.y)+LAYOUT_HEADROOM];
	if (newlines && newlines.count) {
		int newcount = 0;
		CGFloat newypos = styleset.margins.top;
		for (GlkVisualLine *vln in newlines) {
			vln.vlinenum = newcount;
			vln.ypos = newypos;
			newypos += vln.height;
			newcount++;
		}
		
		/* We're inserting at the beginning of the vlines array, so the existing vlines all shift downwards. */
		upextension = newypos - styleset.margins.top;
		NSLog(@"### shifting the universe down %.1f", upextension);
		for (GlkVisualLine *vln in vlines) {
			vln.vlinenum += newcount;
			vln.ypos += upextension;
		}
		endvlineseen += newcount;
		for (VisualLinesView *linev in linesviews) {
			linev.vlinestart += newcount;
			linev.vlineend += newcount;
			linev.ytop += upextension;
			linev.ybottom += upextension;
			linev.frame = CGRectMake(visbounds.origin.x, linev.ytop, visbounds.size.width, linev.height);
		}

		NSRange range = {0,0};
		[vlines replaceObjectsInRange:range withObjectsFromArray:newlines];
		NSLog(@"STV: prepended %d vlines; lines are laid to %d (of %d); yrange is %.1f to %.1f", newlines.count, ((GlkVisualLine *)[vlines lastObject]).linenum, lines.count, ((GlkVisualLine *)[vlines objectAtIndex:0]).ypos, ((GlkVisualLine *)[vlines lastObject]).bottom);
	}
	
	/* Adjust the contentSize to match newly-created vlines. If they were created at the top, we also adjust the contentOffset. If the screen started out clear, scroll straight to the top regardless */
	CGFloat contentheight = self.totalHeight;
	CGSize oldcontentsize = self.contentSize;
	CGFloat vshift = upextension + heightchangeoffset;
	if (wasclear)
		vshift = -self.contentOffset.y;
	if (oldcontentsize.height != contentheight || oldcontentsize.width != visbounds.size.width || vshift != 0) {
		if (vshift != 0) {
			CGPoint offset = self.contentOffset;
			NSLog(@"STV: up-extension %.1f, height-change %.1f; adjusting contentOffset by %.1f (from %.1f to %.1f)", upextension, heightchangeoffset, vshift, offset.y, offset.y+vshift);
			offset.y += vshift;
			if (offset.y < 0)
				offset.y = 0;
			self.contentOffset = offset;
		}

		CGSize newsize = CGSizeMake(visbounds.size.width, contentheight);
		if (!CGSizeEqualToSize(oldcontentsize, newsize)) {
			NSLog(@"STV: contentSize now %.1f,%.1f", visbounds.size.width, contentheight);
			self.contentSize = newsize;
		}
		
		/* Recompute the visual bounds. */
		visbounds = self.bounds;
		visbottom = visbounds.origin.y + visbounds.size.height;
	}
	
	/* Locate the last unseen line (erring on the "seen" side), and bump endvlineseen. */
	int lastseen;
	for (lastseen = vlines.count-1; lastseen >= 0; lastseen--) {
		GlkVisualLine *vln = [vlines objectAtIndex:lastseen];
		if (vln.bottom-1 <= visbottom)
			break;
	}
	if (endvlineseen < lastseen+1)
		endvlineseen = lastseen+1;
	//NSLog(@"STV: endvlineseen is now %d of %d (wasclear %d)", endvlineseen, vlines.count, wasclear);

	/* The endvlineseen value determines whether the buffer's "more" flag is visible. */
	if (!self.moreToSee) {
		[self.superviewAsBufferView setMoreFlag:NO];
	}

	/* If there is a textfield, push it to the new vline bottom. */
	CmdTextField *inputfield = self.superviewAsBufferView.inputfield;
	UIScrollView *inputholder = self.superviewAsBufferView.inputholder;
	if (inputholder) {
		CGRect rect = [self placeForInputField];
		if (!CGRectEqualToRect(inputholder.frame, rect)) {
			NSLog(@"STV: input field shifts to %@", StringFromRect(rect));
			inputfield.frame = CGRectMake(0, 0, rect.size.width, rect.size.height);
			inputholder.contentSize = rect.size;
			inputholder.frame = rect;
		}
	}
	
	/* Now, adjust the bottom of linesviews up or down (deleting or adding VisualLinesViews) until it reaches the bottom of visbounds. 
	 
		Special case (much like the last case): if there are no linesviews at all *and* we're near the bottom, we skip this step; we'll lay out from the bottom up rather than the top down. */
	frombottom = (linesviews.count == 0 && self.scrollPercentage > 0.5);
	
	endlaid = 0;
	bottom = 0;
	while (linesviews.count) {
		VisualLinesView *linev = [linesviews lastObject];
		if (linev.ytop < visbottom) {
			endlaid = linev.vlineend;
			bottom = linev.ybottom;
			break;
		}
		//NSLog(@"### removing last lineview (%d), yrange is %.1f-%.1f", linesviews.count-1, linev.ytop, linev.ybottom);
		[linev removeFromSuperview];
		[linesviews removeLastObject];
	}
	
	while ((!frombottom) && bottom < visbottom && endlaid < vlines.count) {
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
			//NSLog(@"### appending lineview (%d), yrange is %.1f-%.1f", linesviews.count-1, linev.ytop, linev.ybottom);
		}
		
		endlaid = newend;
		bottom = newbottom;
	}
	
	/* Similarly, adjust the top of linesviews up or down. */
	
	if (!vlines.count) {
		startlaid = 0;
		top = 0;
	}
	else {
		startlaid = vlines.count;
		top = self.totalHeight;
	}
	while (linesviews.count) {
		VisualLinesView *linev = [linesviews objectAtIndex:0];
		if (linev.ybottom >= visbounds.origin.y) {
			startlaid = linev.vlinestart;
			top = linev.ytop;
			break;
		}
		//NSLog(@"### removing first lineview, yrange is %.1f-%.1f", linev.ytop, linev.ybottom);
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
			//NSLog(@"### prepending lineview, yrange is %.1f-%.1f", linev.ytop, linev.ybottom);
		}
		
		startlaid = newstart;
		top = newtop;
	}
	
	#ifdef DEBUG
	/* This verifies that I haven't screwed up the consistency of the lines, vlines, linesviews arrays. */
	[self sanityCheck]; //###
	
	#endif // DEBUG
	if (newcontent) {
		NSLog(@"STV: new content time! (wasclear %d)", wasclear);
		if (wasclear) {
			[self.superviewAsBufferView setMoreFlag:self.moreToSee];
		}
		else {
			[self performSelectorOnMainThread:@selector(pageDown) withObject:nil waitUntilDone:NO];
		}
		newcontent = NO;
		wasclear = NO;
	}
}

//###
- (void) debugDisplay {
	CGRect visbounds = self.bounds;
	CGSize contentsize = self.contentSize;
	CGFloat scrolltobottom = contentsize.height - visbounds.size.height;
	NSLog(@"DEBUG: STV is at %.1f of %.1f (contentheight %.1f - visheight %.1f)", self.contentOffset.y, scrolltobottom, contentsize.height, visbounds.size.height);
}

/* Page to the bottom, if necessary. Returns YES if this occurred, NO if we were already there.
 */
- (BOOL) pageToBottom {
	CGRect visbounds = self.bounds;
	CGSize contentsize = self.contentSize;
	CGFloat scrolltobottom = MAX(0, contentsize.height - visbounds.size.height);
	
	if (self.contentOffset.y >= scrolltobottom)
		return NO;

	[self setContentOffset:CGPointMake(0, scrolltobottom) animated:YES];
	return YES;
}

/* Page down, if necessary. Returns YES if further paging is necessary, or NO if we're at the bottom.
 */
- (BOOL) pageDown {
	CGRect visbounds = self.bounds;
	CGSize contentsize = self.contentSize;
	CGFloat scrolltobottom = MAX(0, contentsize.height - visbounds.size.height);
	CGFloat scrollto;
	
	NSLog(@"STV: pageDown finds contentheight %.1f, bounds %.1f, tobottom %.1f", contentsize.height, visbounds.size.height, scrolltobottom);
	
	if (vlines.count && endvlineseen < vlines.count) {
		int topline = endvlineseen;
		if (topline > 0) {
			GlkVisualLine *vln = [vlines objectAtIndex:topline-1];
			scrollto = vln.ypos;
		}
		else {
			GlkVisualLine *vln = [vlines objectAtIndex:topline];
			scrollto = vln.ypos - styleset.charbox.height;
		}
		if (scrollto > scrolltobottom)
			scrollto = scrolltobottom;
		NSLog(@"STV: pageDown one page: %.1f", scrollto);
	}
	else if (vlines.count && self.lastLaidOutLine < lines.count) {
		GlkVisualLine *vln = [vlines lastObject];
		scrollto = vln.ypos;
		if (scrollto > scrolltobottom)
			scrollto = scrolltobottom;
		NSLog(@"STV: pageDown one page (unlaid case): %.1f", scrollto);
	}
	else {
		scrollto = scrolltobottom;
		NSLog(@"STV: pageDown to bottom: %.1f", scrollto);
	}
	
	self.superviewAsBufferView.nowcontentscrolling = YES;
	
	[self setContentOffset:CGPointMake(0, scrollto) animated:YES];
	
	/*
	[UIView beginAnimations:@"autoscroll" context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:0.3];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	self.contentOffset = CGPointMake(0, scrollto);
	[UIView commitAnimations];
	 */
	/*
	[UIView animateWithDuration:0.3 delay:0 options:(UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState)
					 animations:^{ self.contentOffset = CGPointMake(0, scrollto); }
					 completion:nil];
	 */
	
	return (scrollto < scrolltobottom);
}

/* Do the work of laying out the text. Start with line number startline (in the lines array); continue until the total height reaches ymax or the lines run out. Return a temporary array containing the new lines.
*/
- (NSMutableArray *) layoutFromLine:(int)startline forward:(BOOL)forward yMax:(CGFloat)ymax {
	if (wrapwidth <= 4*styleset.charbox.width) {
		/* This isn't going to work out. */
		//NSLog(@"STV: too narrow; refusing layout.");
		return nil;
	}
	
	/* If the loop won't run, we'll save ourselves the effort. */
	if (ymax <= 0)
		return nil;
	
	int loopincrement;
	if (forward) {
		loopincrement = 1;
		if (startline >= lines.count)
			return nil;
	}
	else {
		loopincrement = -1;
		if (startline < 0)
			return nil;
	}
	
	UIFont **fonts = styleset.fonts;
	CGFloat normalpointsize = styleset.charbox.height;
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:32]; // vlines laid out
	NSMutableArray *tmparr = [NSMutableArray arrayWithCapacity:64]; // words in a line
	
	CGFloat ypos = 0;
	
	for (int snum = startline; ypos < ymax; snum += loopincrement) {
		if (forward) {
			if (snum >= lines.count)
				break;
		}
		else {
			if (snum < 0)
				break;
		}
		
		GlkStyledLine *sln = [lines objectAtIndex:snum];
		int vlineforthis = 0;
		
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

			GlkVisualLine *vln = [[[GlkVisualLine alloc] initWithStrings:tmparr styles:styleset] autorelease];
			// vln.vlinesnum will be filled in by the caller.
			vln.ypos = ypos;
			vln.linenum = snum;
			vln.height = maxheight;
			vln.xstart = styleset.margins.left;
			ypos += maxheight;
			
			if (forward) {
				[result addObject:vln];
			}
			else {
				/* If we're laying out in reverse order, the vlines for a single raw line still go in forwards order. So we insert at index 0, then 1, then 2, then (for the next raw line) 0, 1, ... */
				[result insertObject:vln atIndex:vlineforthis];
			}
			vlineforthis++;
			[tmparr removeAllObjects];
		}
	}
		
	NSLog(@"STV: laid out %d vislines, final ypos %.1f (first line %d of %d)", result.count, ypos, startline, lines.count);
	return result;
}

- (void) sanityCheck {
	#ifdef DEBUG
	/*
	NSLog(@"### STV sanity check:");
	NSLog(@"   %d vlines:", vlines.count);
	for (GlkVisualLine *vln in vlines) {
		NSLog(@"    %d (raw %d): %.1f to %.1f, height %.1f", vln.vlinenum, vln.linenum, vln.ypos, vln.bottom, vln.height);
	}
	 */
	
	if (vlines.count) {
		GlkVisualLine *firstvln = [vlines objectAtIndex:0];
		int count = 0;
		int lastraw = firstvln.linenum-1;
		CGFloat bottom = styleset.margins.top;
		for (GlkVisualLine *vln in vlines) {
			if (vln.vlinenum != count)
				NSLog(@"STV-SANITY: (%d) vlinenum %d is not %d", count, vln.vlinenum, count);
			if (vln.linenum != lastraw && vln.linenum != lastraw+1)
				NSLog(@"STV-SANITY: (%d) linenum %d is not %d or +1", count, vln.linenum, lastraw);
			if (vln.ypos != bottom)
				NSLog(@"STV-SANITY: (%d) ypos %.1f is not %.1f", count, vln.ypos, bottom);
			bottom = vln.bottom;
			lastraw = vln.linenum;
			count++;
		}
	}
	
	int count = 0;
	for (UIView *subview in self.subviews) {
		if ([subview isKindOfClass:[VisualLinesView class]])
			count++;
	}
	
	if (count != linesviews.count)
		NSLog(@"STV-SANITY: wrong number of subviews (%d, not %d)", count, linesviews.count);
	
	if (linesviews.count > 0) {
		VisualLinesView *firstlinev = [linesviews objectAtIndex:0];
		int lastv = firstlinev.vlinestart;
		CGFloat bottom = firstlinev.ytop;
		
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
	#endif // DEBUG
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	//NSLog(@"STV: Touch began (%d)", event.allTouches.count);
	if (event.allTouches.count > 1) {
		taptracking = NO;
		return;
	}
	
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	if (now - taplastat > 0.5)
		tapnumber = 0;
	
	taptracking = YES;
	taplastat = now;
	UITouch *touch = [[event touchesForView:self] anyObject];
	taploc = [touch locationInView:self];
	
	//### start timer for select-loupe popup
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if (!taptracking)
		return;
	
	//NSLog(@"STV: Touch moved (%d)", event.allTouches.count);
	UITouch *touch = [[event touchesForView:self] anyObject];
	CGPoint loc = [touch locationInView:self];
	
	if (DistancePoints(loc, taploc) > 20) {
		//NSLog(@"STV: Touch moved too far");
		taptracking = NO;
		taplastat = 0; // the past
		return;
	}
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (!taptracking)
		return;
	
	//NSLog(@"STV: Touch ended");
	taptracking = NO;
	
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	if (now - taplastat > 0.75) {
		//NSLog(@"STV: Touch took too long");
		taptracking = NO;
		taplastat = 0; // the past
		return;		
	}
	
	tapnumber++;
	taplastat = now;
	NSLog(@"### tap %d!", tapnumber);
	
	if (self.moreToSee) {
		/* If paging, all taps scroll down. */
		tapnumber = 0;
		[self pageDown];
		return;
	}
	
	GlkWinBufferView *winv = [self superviewAsBufferView];
	
	/* If there is no input line, ignore single-tap. On double-tap, scroll to bottom. */
	if (!winv.inputfield) {
		if (tapnumber >= 2) {
			tapnumber = 0;
			[self pageToBottom];
		}
		return;
	}
	
	/* Otherwise, single-tap focuses the input line. On double-tap, paste a word in. */
	if (tapnumber == 1) {
		if (![winv.inputfield isFirstResponder]) {
			tapnumber = 0;
			[self pageToBottom];
			[winv.inputfield becomeFirstResponder];
		}
	}
	else {
		tapnumber = 0;
		GlkVisualLine *vln = [self lineAtPos:taploc.y];
		if (vln) {
			CGRect rect;
			NSString *wd = [vln wordAtPos:taploc.x inBox:&rect];
			if (wd) {
				/* Send an animated label flying downhill */
				rect = CGRectInset(rect, -4, -2);
				UILabel *label = [[[UILabel alloc] initWithFrame:rect] autorelease];
				label.font = styleset.fonts[style_Normal];
				label.text = wd;
				label.textAlignment = UITextAlignmentCenter;
				label.backgroundColor = nil;
				label.opaque = NO;
				[self addSubview:label];
				CGPoint newpt = RectCenter(winv.inputholder.frame);
				CGSize curinputsize = [winv.inputfield.text sizeWithFont:winv.inputfield.font];
				newpt.x = winv.inputholder.frame.origin.x + curinputsize.width + 0.5*rect.size.width;
				[UIView beginAnimations:@"labelFling" context:label];
				[UIView setAnimationDelegate:self];
				[UIView setAnimationDuration:0.3];
				[UIView setAnimationDidStopSelector:@selector(labelFlingEnd:finished:context:)];
				[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
				label.center = newpt;
				label.alpha = 0.25;
				[UIView commitAnimations];
				
				[winv.inputfield applyInputString:wd replace:NO];
			}
		}
	}
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	//NSLog(@"STV: Touch cancelled");
	taptracking = NO;
	taplastat = 0; // the past
}

- (void) labelFlingEnd:(NSString *)animid finished:(NSNumber *)finished context:(void *)context {
	UILabel *label = (UILabel *)context;
	[label removeFromSuperview];
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
		
		self.backgroundColor = styleset.backgroundcolor;
		//self.backgroundColor = [UIColor colorWithRed:(random()%127+128)/256.0 green:(random()%127+128)/256.0 blue:1 alpha:1]; //###
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
		pt.x = vln.xstart;
		for (GlkVisualString *vwd in vln.arr) {
			UIFont *font = fonts[vwd.style];
			CGSize wordsize = [vwd.str drawAtPoint:pt withFont:font];
			pt.x += wordsize.width;
		}
	}
}

@end


