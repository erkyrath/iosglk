/* StyledTextView.m: Rich text view class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "StyledTextView.h"
#import "IosGlkViewController.h"
#import "GlkWinBufferView.h"
#import "GlkWindowState.h"
#import "CmdTextField.h"
#import "GlkUtilTypes.h"
#import "GlkAccessTypes.h"
#import "StyleSet.h"
#import "TextSelectView.h"
#import "GlkUtilities.h"

#define LAYOUT_HEADROOM (1000)
#define STRIPE_WIDTH (100)

@implementation StyledTextView

@synthesize slines;
@synthesize vlines;
@synthesize linesviews;
@synthesize styleset;
@synthesize selectionview;
@synthesize selectionarea;

- (id) initWithFrame:(CGRect)frame styles:(StyleSet *)stylesval {
	self = [super initWithFrame:frame];
	if (self) {
		firstsline = 0;
		self.slines = [NSMutableArray arrayWithCapacity:32];
		self.vlines = [NSMutableArray arrayWithCapacity:32];
		self.linesviews = [NSMutableArray arrayWithCapacity:32];
		wasclear = YES;
		wasrefresh = NO;

		totalheight = self.bounds.size.height;
		totalwidth = self.bounds.size.width;

		self.alwaysBounceVertical = YES;
		self.canCancelContentTouches = YES;
		idealcontentheight = self.bounds.size.height;
		self.contentSize = self.bounds.size;
		
		[self acceptStyleset:stylesval];
		
		selectvstart = -1;
		selectvend = -1;
		
		taplastat = 0; // the past
	}
	return self;
}

- (void) dealloc {
	self.slines = nil;
	self.vlines = nil;
	self.linesviews = nil;
	self.styleset = nil;
	self.selectionview = nil;
	[super dealloc];
}

- (GlkWinBufferView *) superviewAsBufferView {
	return (GlkWinBufferView *)self.superview;
}

- (UIScrollView *) inputholder {
	return ((GlkWinBufferView *)self.superview).inputholder;
}

- (CmdTextField *) inputfield {
	return ((GlkWinBufferView *)self.superview).inputfield;
}

- (void) acceptStyleset:(StyleSet *)stylesval {
	self.styleset = stylesval;
	wrapwidth = totalwidth - styleset.margintotal.width;
	self.backgroundColor = styleset.backgroundcolor;
}

/* Return the scroll position in the page, between 0.0 and 1.0. This is only an approximation, because we don't always have the whole page laid out (into vlines). If the page content is empty or shorter than its height, returns 0.
 */
- (CGFloat) scrollPercentage {
	CGSize vissize = self.bounds.size;
	if (idealcontentheight <= vissize.height)
		return 0;
	CGFloat res = self.contentOffset.y / (idealcontentheight - vissize.height);
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
	
	if (self.lastLaidOutLine < firstsline+self.slines.count) {
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

/* Import the given lines (as taken from the GlkWindowBuffer).
 */
- (void) updateWithLines:(NSArray *)uplines dirtyFrom:(int)linesdirtyfrom clearCount:(int)newclearcount refresh:(BOOL)refresh {
	//NSLog(@"STV: updating, got %d lines %s", uplines.count, ((clearcount != newclearcount)?"(clear-bump)":""));
	newcontent = YES;
	
	if (refresh) {
		/* We're refreshing old content. That means the player has seen it. */
		//NSLog(@"STV: ...I believe this is a refresh, not really a clear-bump.");
		clearcount = newclearcount;
		[vlines removeAllObjects];
		endvlineseen = 0;
		wasrefresh = YES;
	}
	else if (clearcount != newclearcount) {
		/* The update contains a page-clear. The player has not seen this stuff. */
		clearcount = newclearcount;
		[vlines removeAllObjects];
		endvlineseen = 0;
		wasclear = YES;
	}

	[slines removeAllObjects];
	firstsline = 0;
	if (uplines.count) {
		GlkStyledLine *firstsln = [uplines objectAtIndex:0];
		firstsline = firstsln.index;
		[slines addObjectsFromArray:uplines];
	}

	/* Some lines may have been trimmed from the beginning. If so, throw away vlines at the beginning. */
	int trimcount = 0;
	for (GlkVisualLine *vln in vlines) {
		if (vln.linenum >= firstsline)
			break;
		trimcount++;
	}
	if (trimcount > 0) {
		//NSLog(@"STV: trimming %d vlines from top; firstsline now %d", trimcount, firstsline);
		endvlineseen -= trimcount;
		if (endvlineseen < 0)
			endvlineseen = 0;
		NSRange range;
		range.location = 0;
		range.length = trimcount;
		[vlines removeObjectsInRange:range];
		CGFloat yshift = 0;
		if (vlines.count) {
			GlkVisualLine *vln = [vlines objectAtIndex:0];
			yshift = vln.ypos - styleset.margins.top;
			CGPoint offset = self.contentOffset;
			offset.y -= yshift;
			self.contentOffset = offset;
		}
		for (GlkVisualLine *vln in vlines) {
			vln.vlinenum -= trimcount;
			vln.ypos -= yshift;
		}
	}
	
	/* If any of the update lines replace known ones, we may have to throw away vlines at the end. */
	while (vlines.count > 0) {
		GlkVisualLine *vln = [vlines lastObject];
		if (vln.linenum < linesdirtyfrom)
			break;
		[vlines removeLastObject];
	}
	if (endvlineseen > vlines.count)
		endvlineseen = vlines.count;

	/* Now trash all the VisualLinesViews. We'll create new ones at the next layout call. */
	//NSLog(@"### removing all linesviews (for update)");
	[self uncacheLayoutAndVLines:NO];
}

- (void) uncacheLayoutAndVLines:(BOOL)andvlines {
	[self clearTouchTracking];
	[self clearSelection];

	if (andvlines) {
		[vlines removeAllObjects];
		endvlineseen = 0;
	}
	
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
		//NSLog(@"STV: width has changed! now %.01f (wrap %.01f)", totalwidth, wrapwidth);
		
		/* Trash all laid-out lines and VisualLinesViews. */
		//NSLog(@"### removing all linesviews (for width change)");
		[self uncacheLayoutAndVLines:YES];
	}
	
	/* If the page height has changed, we will want to do a vertical shift later on. (But if the width changed too, forget it -- that's a complete re-layout.)
	 
		(Also, if the view is expanding and we're at the (old) bottom, the shift may already have been applied -- I guess when the frame changed. In that case, we leave heightchangeoffset at zero. We also leave heightchangeoffset at zero if we're *really* at the bottom. Honestly I've lost track of why this all works.)
	 */
	CGFloat heightchangeoffset = 0;
	if (totalheight != visbounds.size.height) {
		if (wasatbottom && vlines.count > 0 && self.contentOffset.y+visbounds.size.height < idealcontentheight) {
			heightchangeoffset = totalheight - visbounds.size.height;
		}
		totalheight = visbounds.size.height;
	}
	
	/* Extend vlines down until it's past the bottom of visbounds. (Or we're out of lines.) 
	 
		Special case: if there are no vlines at all *and* we're near the bottom, we skip this step; we'll lay out from the bottom up rather than the top down. (If there are vlines, we always extend that range both ways.) 
	 */
	BOOL newlayout = (vlines.count == 0);
	BOOL frombottom = NO;
	if (newlayout) {
		frombottom = (!wasclear && self.scrollPercentage > 0.5);
		if (wasrefresh)
			frombottom = YES;
	}
	/*
	if (frombottom)
		NSLog(@"### frombottom case! (wasclear %d, wasrefresh %d)", wasclear, wasrefresh);
	*/
	
	CGFloat bottom = styleset.margins.top;
	int endlaid = firstsline;
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
		//NSLog(@"STV: appended %d vlines; lines are laid to %d (of %d to %d); yrange is %.1f to %.1f", newlines.count, ((GlkVisualLine *)[vlines lastObject]).linenum, firstsline, firstsline+slines.count, ((GlkVisualLine *)[vlines objectAtIndex:0]).ypos, ((GlkVisualLine *)[vlines lastObject]).bottom);
	}
	
	/* Extend vlines up, similarly. */
	
	CGFloat upextension = 0;
	
	CGFloat top = visbottom;
	int startlaid = firstsline+slines.count;
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
		//NSLog(@"### shifting the universe down %.1f", upextension);
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
		//NSLog(@"STV: prepended %d vlines; lines are laid to %d (of %d to %d); yrange is %.1f to %.1f", newlines.count, ((GlkVisualLine *)[vlines lastObject]).linenum, firstsline, firstsline+slines.count, ((GlkVisualLine *)[vlines objectAtIndex:0]).ypos, ((GlkVisualLine *)[vlines lastObject]).bottom);
	}
	
	/* Adjust the contentSize to match newly-created vlines. If they were created at the top, we also adjust the contentOffset. If the screen started out clear, scroll straight to the top regardless */
	CGFloat contentheight = self.totalHeight;
	CGSize oldcontentsize = CGSizeMake(self.contentSize.width, idealcontentheight);
	CGFloat vshift = upextension + heightchangeoffset;
	if (wasrefresh)
		vshift = (contentheight-oldcontentsize.height)-self.contentOffset.y;
	else if (wasclear)
		vshift = -self.contentOffset.y;
	if (oldcontentsize.height != contentheight || oldcontentsize.width != visbounds.size.width || vshift != 0) {
		if (vshift != 0) {
			CGPoint offset = self.contentOffset;
			//NSLog(@"STV: up-extension %.1f, height-change %.1f; adjusting contentOffset by %.1f (from %.1f to %.1f)", upextension, heightchangeoffset, vshift, offset.y, offset.y+vshift);
			offset.y += vshift;
			if (oldcontentsize.height == contentheight) {
				/* This is conditional because iOS does some adjustment when the contentSize changes (below). With that adjustment, we don't need this offset limitation -- in fact, it breaks some cases. Without that adjustment, we do need it. */
				if (offset.y > oldcontentsize.height - visbounds.size.height)
					offset.y = oldcontentsize.height - visbounds.size.height;
			}
			if (offset.y < 0)
				offset.y = 0;
			self.contentOffset = offset;
		}

		/* This is the one magic place where contentSize changes. Except for the place farther down where it can shrink back to idealcontentheight. */
		idealcontentheight = contentheight;
		CGSize newsize = CGSizeMake(visbounds.size.width, contentheight);
		CGSize truecontentsize = self.contentSize;
		if (newsize.height < truecontentsize.height && !newlayout)
			newsize.height = truecontentsize.height;
		if (!CGSizeEqualToSize(truecontentsize, newsize)) {
			//NSLog(@"STV: contentSize now %@ (was %@)", StringFromSize(newsize), StringFromSize(oldcontentsize));
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
	CmdTextField *inputfield = self.inputfield;
	UIScrollView *inputholder = self.inputholder;
	if (inputholder) {
		CGRect rect = [self placeForInputField];
		if (!CGRectEqualToRect(inputholder.frame, rect)) {
			//NSLog(@"STV: input field shifts to %@", StringFromRect(rect));
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
	
	/* Similarly, adjust the top of linesviews up or down. (startlaid now counts vlines.) */
	
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

	/* Reduce the contentsize if it's over idealcontentheight. Also, check whether we're scrolled to the bottom. (Allowing a small margin of error.) We'll be checking this next update. */
	if (YES) {
		CGFloat offset = (self.contentOffset.y+visbounds.size.height) - idealcontentheight;
		CGFloat maxvis = (self.contentOffset.y+visbounds.size.height);
		CGFloat limit = MAX(maxvis, idealcontentheight);
		wasatbottom = (offset >= -2.0);
		//NSLog(@"### end of layout: wasatbottom now %d, based on %f", wasatbottom, offset);
		CGSize truecontentsize = self.contentSize;
		if (truecontentsize.height > limit) {
			truecontentsize.height = limit;
			self.contentSize = truecontentsize;
		}
	}
	
	if (newcontent) {
		//NSLog(@"STV: new content time! (wasclear %d)", wasclear);
		if (wasclear) {
			[self.superviewAsBufferView setMoreFlag:self.moreToSee];
		}
		else {
			[self performSelectorOnMainThread:@selector(pageDown:) withObject:nil waitUntilDone:NO];
		}
		newcontent = NO;
		wasclear = NO;
		wasrefresh = NO;
	}

	if (!self.dragging && !self.decelerating)
		[self showSelectionMenu];
}

/* Page to the bottom, if necessary. Returns YES if this occurred, NO if we were already there.
 */
- (BOOL) pageToBottom {
	CGRect visbounds = self.bounds;
	CGFloat scrolltobottom = MAX(0, idealcontentheight - visbounds.size.height);
	
	if (self.contentOffset.y >= scrolltobottom)
		return NO;

	[self setContentOffset:CGPointMake(0, scrolltobottom) animated:YES];
	return YES;
}

/* Page down, if necessary. Returns YES if further paging is necessary, or NO if we're at the bottom.
 
	Sender is self if the page was initiated by the user, or nil if it was initiated by layout. (Yes, that's awful.)
 */
- (BOOL) pageDown:(id)sender {
	CGRect visbounds = self.bounds;
	CGFloat scrolltobottom = MAX(0, idealcontentheight - visbounds.size.height);
	CGFloat scrollto;
	
	//NSLog(@"STV: pageDown finds contentheight %.1f, bounds %.1f, tobottom %.1f", contentsize.height, visbounds.size.height, scrolltobottom);

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL usemore = ![defaults boolForKey:@"NoMorePrompt"];

	if (sender && !usemore) {
		scrollto = scrolltobottom;
		//NSLog(@"STV: pageDown to bottom: %.1f", scrollto);
	}
	else if (vlines.count && endvlineseen < vlines.count) {
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
		//NSLog(@"STV: pageDown one page: %.1f", scrollto);
	}
	else if (vlines.count && self.lastLaidOutLine < firstsline+slines.count) {
		GlkVisualLine *vln = [vlines lastObject];
		scrollto = vln.ypos;
		if (scrollto > scrolltobottom)
			scrollto = scrolltobottom;
		//NSLog(@"STV: pageDown one page (unlaid case): %.1f", scrollto);
	}
	else {
		scrollto = scrolltobottom;
		//NSLog(@"STV: pageDown to bottom: %.1f", scrollto);
	}
	
	IosGlkViewController *viewc = [IosGlkViewController singleton];
	//### check preference!
	if (NO && scrollto < scrolltobottom && viewc.keyboardIsShown) {
		[viewc hideKeyboard];
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
		if (startline >= firstsline+slines.count)
			return nil;
	}
	else {
		loopincrement = -1;
		if (startline < firstsline)
			return nil;
	}
	
	/* Requires iOS 4 and up */
	BOOL lineheightavail = ([UIFont instancesRespondToSelector:@selector(lineHeight)]);
	
	UIFont **fonts = styleset.fonts;
	CGFloat leading = styleset.leading;
	CGFloat normalpointsize = styleset.charbox.height; // includes leading
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:32]; // vlines laid out
	NSMutableArray *tmparr = [NSMutableArray arrayWithCapacity:64]; // words in a line

	CGFloat ypos = 0;
	
	for (int snum = startline; ypos < ymax; snum += loopincrement) {
		if (forward) {
			if (snum >= firstsline+slines.count)
				break;
		}
		else {
			if (snum < firstsline)
				break;
		}
		
		GlkStyledLine *sln = [slines objectAtIndex:snum-firstsline];
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
			CGFloat maxheight = 0.0;
			//CGFloat maxascender = 0.0;
			//CGFloat maxdescender = 0.0;
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
					
					CGFloat lineheight = (lineheightavail ? (sfont.lineHeight) : (sfont.pointSize+2));
					lineheight += leading;
					if (maxheight < lineheight)
						maxheight = lineheight;
					/*
					if (maxascender < sfont.ascender)
						maxascender = sfont.ascender;
					if (maxdescender > sfont.descender)
						maxdescender = sfont.descender;
					 */
						
					wdpos = wdend;
				}
				
				if (wdpos >= strlen) {
					sstr = nil;
				}
			}
			
			if (maxheight < 2)
				maxheight = normalpointsize;

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
		
	//NSLog(@"STV: laid out %d vislines, final ypos %.1f (first line %d of %d)", result.count, ypos, startline, slines.count);
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

- (BOOL) canBecomeFirstResponder {
	return YES;
}

- (BOOL) becomeFirstResponder {
	BOOL res = [super becomeFirstResponder];
	if (!res)
		return NO;
	
	[[IosGlkViewController singleton] textSelectionWindow:self.superviewAsBufferView.winstate.tag];
	return YES;
}

- (BOOL) resignFirstResponder {
	[self clearSelection];
	[[IosGlkViewController singleton] textSelectionWindow:nil];
	return YES;
}

- (void) copy:(id)sender {
	/* Keep the menu up after the copy command */
	[UIMenuController sharedMenuController].menuVisible = YES;
	
	if (!self.anySelection)
		return;

	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:2*(selectvend-selectvstart+1)];
	int lastln = -1;

	for (int ix=selectvstart; ix<selectvend; ix++) {
		GlkVisualLine *vln = [vlines objectAtIndex:ix];
		if (lastln != -1) {
			if (lastln != vln.linenum)
				[arr addObject:@"\n"];
			else
				[arr addObject:@" "];
		}
		lastln = vln.linenum;
		[arr addObject:vln.concatLine];
	}
	
	NSString *str = [arr componentsJoinedByString:@""];
	[UIPasteboard generalPasteboard].string = str;
}

- (void) clearTouchTracking {
	taptracking = NO;
	tapseldragging = SelDrag_none;
	taplastat = 0; // the past
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(switchToTextSelection) object:nil];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(giveUpTapCombo) object:nil];
}

- (BOOL) anySelection {
	return (selectvstart >= 0 && selectvend >= 0 && selectvstart < selectvend);
}

- (void) showSelectionMenu {
	if (!self.anySelection)
		return;
	
	if (![self isFirstResponder])
		return;
	
	UIMenuController *menucon = [UIMenuController sharedMenuController];
	[menucon setTargetRect:selectionarea inView:self];
	if (!menucon.menuVisible)
		[menucon setMenuVisible:YES animated:YES];
}

- (void) setSelectionStart:(int)firstvln end:(int)endvln {
	if (selectvstart == firstvln && selectvend == endvln)
		return;

	NSAssert(firstvln >= 0 && firstvln < vlines.count && endvln > firstvln && endvln <= vlines.count, @"setSelectionStart out of bounds");
	selectvstart = firstvln;
	selectvend = endvln;
	
	CGRect rect = self.bounds; // for x and width
	GlkVisualLine *vln = [vlines objectAtIndex:firstvln];
	rect.origin.y = vln.ypos;
	vln = [vlines objectAtIndex:endvln-1];
	rect.size.height = vln.bottom - rect.origin.y;
	selectionarea = rect;
	
	if (!selectionview) {
		self.selectionview = [[[TextSelectView alloc] initWithFrame:CGRectZero] autorelease];
		[self addSubview:selectionview];
		
		rect.origin = RectCenter(selectionarea);
		rect.size = CGSizeMake(1,1);
		[selectionview setOutline:CGRectInset(rect, -5, -5) animated:NO];
	}
	
	[selectionview setArea:selectionarea];
}

- (void) clearSelection {
	if (!self.anySelection)
		return;
	selectvstart = -1;
	selectvend = -1;
	selectionarea = CGRectNull;
	
	if (selectionview) {
		[selectionview removeFromSuperview];
		self.selectionview = nil;
	}

	UIMenuController *menucon = [UIMenuController sharedMenuController];
	if (menucon.menuVisible)
		[menucon setMenuVisible:NO animated:YES];
}

- (void) selectParagraphAt:(CGPoint)loc {
	GlkVisualLine *vln = [self lineAtPos:loc.y];
	if (!vln) {
		[self clearSelection];
		return;
	}
	
	int slinenum = vln.linenum;
	
	int firstvln = vln.vlinenum;
	int endvln = firstvln+1;
	while (firstvln > 0) {
		vln = [vlines objectAtIndex:firstvln-1];
		if (vln.linenum != slinenum)
			break;
		firstvln--;
	}
	while (endvln < vlines.count) {
		vln = [vlines objectAtIndex:endvln];
		if (vln.linenum != slinenum)
			break;
		endvln++;
	}
	
	[self setSelectionStart:firstvln end:endvln];
	[selectionview setOutline:selectionarea animated:YES];
}

- (void) selectMoveEdgeAt:(CGPoint)loc mode:(SelDragMode)mode {
	GlkVisualLine *vln = [self lineAtPos:loc.y];
	if (!vln) {
		return;
	}
	
	int firstvln = selectvstart;
	int endvln = selectvend;
	
	CGRect rect = selectionarea;
	CGFloat ytop = rect.origin.y;
	CGFloat ybottom = rect.origin.y+rect.size.height;

	if (mode == SelDrag_topedge) {
		firstvln = vln.vlinenum;
		if (firstvln > endvln-1)
			firstvln = endvln-1;
		
		ytop = loc.y;
		if (ytop > ybottom-4)
			ytop = ybottom-4;
	}
	else {
		endvln = vln.vlinenum+1;
		if (endvln < firstvln+1)
			endvln = firstvln+1;
		
		ybottom = loc.y;
		if (ybottom < ytop+4)
			ybottom = ytop+4;
	}
	
	rect.origin.y = ytop;
	rect.size.height = ybottom-ytop;
	
	[self setSelectionStart:firstvln end:endvln];
	[selectionview setOutline:rect animated:YES];
}

- (BOOL) touchesShouldCancelInContentView:(UIView *)view {
	if (taptracking && tapseldragging)
		return NO;
	return YES;
}

- (void) switchToTextSelection {
	tapseldragging = SelDrag_paragraph;
	[self selectParagraphAt:taploc];
}

- (void) giveUpTapCombo {
	//NSLog(@"### giveUpTapCombo: %d", tapnumber);
	if (tapnumber == 1) {
		IosGlkViewController *viewc = [IosGlkViewController singleton];
		GlkWindowView *winv = viewc.preferredInputWindow;
		if (winv && winv.inputfield && winv.inputfield.isFirstResponder) {
			[winv.inputfield resignFirstResponder];
		}
	}
	tapnumber = 0;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	//NSLog(@"STV: Touch began (%d)", event.allTouches.count);
	if (event.allTouches.count > 1) {
		[self clearTouchTracking];
		return;
	}
	
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	if (now - taplastat > 0.5)
		tapnumber = 0;
	
	taptracking = YES;
	taplastat = now;
	UITouch *touch = [[event allTouches] anyObject];
	taploc = [touch locationInView:self];
	
	if (self.anySelection) {
		/* If the tap is on the upper or lower handle, go with that mode. */
		CGFloat xcenter = selectionarea.origin.x + 0.5*selectionarea.size.width;
		if (taploc.x > xcenter-HANDLE_RADIUS && taploc.x < xcenter+HANDLE_RADIUS) {
			CGFloat ypos = selectionarea.origin.y;
			if (taploc.y > ypos-HANDLE_RADIUS && taploc.y < ypos+HANDLE_RADIUS)
				tapseldragging = SelDrag_topedge;
			ypos = selectionarea.origin.y + selectionarea.size.height;
			if (taploc.y > ypos-HANDLE_RADIUS && taploc.y < ypos+HANDLE_RADIUS)
				tapseldragging = SelDrag_bottomedge;
			if (tapseldragging) {
				[selectionview setOutline:selectionarea animated:YES];
				return;
			}
		}
	}
	
	/* Normal tap-tracking mode. But we start the timer for switching into paragraph-select mode. */
	[self performSelector:@selector(switchToTextSelection) withObject:nil afterDelay:0.5];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if (!taptracking)
		return;
	
	UITouch *touch = [[event allTouches] anyObject];
	CGPoint loc = [touch locationInView:self];
	
	if (tapseldragging) {
		/* Text selection */
		if (tapseldragging == SelDrag_topedge || tapseldragging == SelDrag_bottomedge) {
			[self selectMoveEdgeAt:loc mode:tapseldragging];
		}
		else {
			[self selectParagraphAt:loc];
		}
	}
	else {
		/* Double-tap detection */
		if (DistancePoints(loc, taploc) > 20) {
			//NSLog(@"STV: Touch moved too far");
			[self clearTouchTracking];
			return;
		}
	}
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	//NSLog(@"STV: Touch ended");
	if (!taptracking)
		return;
	
	BOOL wasseldragging = (tapseldragging != SelDrag_none);
	
	taptracking = NO;
	tapseldragging = SelDrag_none;
	// leave taplastat intact
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(switchToTextSelection) object:nil];
	
	if (wasseldragging) {
		/* Text selection. We become the first responder (not the input field, but the text view itself). */
		[selectionview hideOutlineAnimated:YES];
		[self becomeFirstResponder];
		[self showSelectionMenu];
		return;
	}
	
	[self clearSelection];

	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	if (now - taplastat > 0.75) {
		//NSLog(@"STV: Touch took too long");
		[self clearTouchTracking];
		return;		
	}
	
	tapnumber++;
	taplastat = now;
	//NSLog(@"### tap %d!", tapnumber);
	[self performSelector:@selector(giveUpTapCombo) withObject:nil afterDelay:0.5];
	
	if (self.moreToSee) {
		/* If paging, all taps scroll down. */
		tapnumber = 0;
		[self pageDown:self];
		return;
	}
	
	IosGlkViewController *viewc = [IosGlkViewController singleton];
	GlkWindowView *winv = viewc.preferredInputWindow;
	
	/* If there is no input line (anywhere), ignore single-tap. On double-tap, scroll to bottom. */
	if (!winv || !winv.inputfield) {
		if (viewc.vmexited) {
			tapnumber = 0;
			[viewc postGameOver];
			return;
		}
		if (tapnumber >= 2) {
			tapnumber = 0;
			[self pageToBottom];
		}
		return;
	}
	
	/* Otherwise, single-tap focuses or defocusses the input line. On double-tap, paste a word in. */
	
	if (tapnumber == 1) {
		/* Single-tap... */
		if (![winv.inputfield isFirstResponder]) {
			tapnumber = 0;
			[self pageToBottom];
			[winv.inputfield becomeFirstResponder];
		}
		/* If the input field *is* focussed, we don't do anything yet. (This might be the beginning of a double-tap.) The giveUpTapCombo callback, coming in 0.5 second, will drop the keyboard. */
	}
	else if (!winv.inputfield.singleChar) {
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
				
				/* Put the word into the input field */
				[winv.inputfield applyInputString:wd replace:NO];
			}
		}
	}
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	//NSLog(@"STV: Touch cancelled");
	[self clearTouchTracking];
}

- (void) labelFlingEnd:(NSString *)animid finished:(NSNumber *)finished context:(void *)context {
	UILabel *label = (UILabel *)context;
	[label removeFromSuperview];
}

- (BOOL) isAccessibilityElement {
	/* A UIAccessibilityContainer is never an element itself. */
	return NO;
}

- (NSInteger) accessibilityElementCount {
	/* Every vline is an accessibility element. If an input field exists, that's one too, at the end of the list. */
	int count = vlines.count;
	if (self.inputholder)
		count++;
	return count;
}

- (id) accessibilityElementAtIndex:(NSInteger)index {
	if (index == vlines.count) {
		UIScrollView *inputholder = self.inputholder;
		if (inputholder)
			return inputholder;
	}
	
	if (index >= vlines.count)
		return nil;
	
	GlkVisualLine *vln = [vlines objectAtIndex:index];
	return [vln accessElementInContainer:self];
}

- (NSInteger) indexOfAccessibilityElement:(id)element {
	if (!element)
		return NSNotFound;
	
	if (element == self.inputholder)
		return vlines.count;
	
	if (![element isKindOfClass:[GlkAccVisualLine class]])
		return NSNotFound;
	GlkAccVisualLine *el = (GlkAccVisualLine *)element;
	if (!el.line)
		return NSNotFound;
	int index = el.line.vlinenum;
	if (index < 0 || index >= vlines.count)
		return NSNotFound;
	return index;
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
		self.userInteractionEnabled = YES;
		
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
		
	UIFont **fonts = styleset.fonts;
	UIColor **colors = styleset.colors;
	
	/* We'll be using a limited list of colors, so it makes sense to track them by identity. */
	UIColor *lastcolor = nil;
	
	for (GlkVisualLine *vln in vlines) {
		CGFloat maxascend = 0.0;
		for (GlkVisualString *vwd in vln.arr) {
			UIFont *font = fonts[vwd.style];
			CGFloat ascend = font.ascender;
			if (maxascend < ascend)
				maxascend = ascend;
		}
		CGFloat ymin = vln.ypos - ytop;
		CGPoint pt;
		pt.y = ymin;
		pt.x = vln.xstart;
		for (GlkVisualString *vwd in vln.arr) {
			UIFont *font = fonts[vwd.style];
			UIColor *color = colors[vwd.style];
			if (color != lastcolor) {
				CGContextSetFillColorWithColor(gc, color.CGColor);
				lastcolor = color;
			}
			pt.y = ymin + floorf(maxascend - font.ascender);
			// for descenders: pt.y = (ymin + vln.height - font.lineHeight) - floorf(font.descender - mindescend)
			
			CGSize wordsize = [vwd.str drawAtPoint:pt withFont:font];
			pt.x += wordsize.width;
		}
	}
}

@end


