/* GlkWinGridView.m: Glk textgrid window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "GlkWinGridView.h"
#import "IosGlkViewController.h"
#import "GlkWindowState.h"
#import "GlkAppWrapper.h"
#import "StyleSet.h"
#import "CmdTextField.h"
#import "TextSelectView.h"
#import "GlkAccessTypes.h"
#import "GlkUtilTypes.h"
#import "GlkUtilities.h"


@implementation GlkWinGridView

@synthesize lines;
@synthesize selectionview;

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
	self.selectionview = nil;
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

- (BOOL) canBecomeFirstResponder {
	return YES;
}

- (BOOL) becomeFirstResponder {
	BOOL res = [super becomeFirstResponder];
	if (!res)
		return NO;
	
	[[IosGlkViewController singleton] textSelectionWindow:winstate.tag];
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
	
	for (int ix=selectvstart; ix<selectvend; ix++) {
		GlkStyledLine *vln = [lines objectAtIndex:ix];
		[arr addObject:vln.concatLine];
		[arr addObject:@"\n"];
	}
	
	NSString *str = [arr componentsJoinedByString:@""];
	[UIPasteboard generalPasteboard].string = str;
}

- (void) clearTouchTracking {
	taptracking = NO;
	tapseldragging = SelDrag_none;
	taplastat = 0; // the past
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(switchToTextSelection) object:nil];
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

- (void) setSelectionStart:(int)firstln end:(int)endln {
	if (selectvstart == firstln && selectvend == endln)
		return;
	
	NSAssert(firstln >= 0 && firstln < lines.count && endln > firstln && endln <= lines.count, @"setSelectionStart out of bounds");
	selectvstart = firstln;
	selectvend = endln;

	CGSize charbox = styleset.charbox;
	CGFloat marginoffsety = styleset.margins.top;
	
	CGRect rect = self.bounds; // for x and width
	rect.origin.y = marginoffsety + firstln * charbox.height;
	rect.size.height = (endln - firstln) * charbox.height;
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
	CGSize charbox = styleset.charbox;
	CGFloat marginoffsety = styleset.margins.top;

	int slinenum = floorf((loc.y - marginoffsety) / charbox.height);
	if (slinenum < 0 || slinenum >= lines.count) {
		[self clearSelection];
		return;
	}
	
	[self setSelectionStart:slinenum end:slinenum+1];
	[selectionview setOutline:selectionarea animated:YES];
}

- (void) selectMoveEdgeAt:(CGPoint)loc mode:(SelDragMode)mode {
	CGSize charbox = styleset.charbox;
	CGFloat marginoffsety = styleset.margins.top;
	
	int slinenum = floorf((loc.y - marginoffsety) / charbox.height);
	if (slinenum < 0 || slinenum >= lines.count) {
		return;
	}
	
	int firstvln = selectvstart;
	int endvln = selectvend;
	
	CGRect rect = selectionarea;
	CGFloat ytop = rect.origin.y;
	CGFloat ybottom = rect.origin.y+rect.size.height;
	
	if (mode == SelDrag_topedge) {
		firstvln = slinenum;
		if (firstvln > endvln-1)
			firstvln = endvln-1;
		
		ytop = loc.y;
		if (ytop > ybottom-4)
			ytop = ybottom-4;
	}
	else {
		endvln = slinenum+1;
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

- (void) switchToTextSelection {
	tapseldragging = SelDrag_paragraph;
	[self selectParagraphAt:taploc];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	//NSLog(@"WGV: Touch began (%d)", event.allTouches.count);
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
			//NSLog(@"WGV: Touch moved too far");
			[self clearTouchTracking];
			return;
		}
	}
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (!taptracking)
		return;
	
	BOOL wasseldragging = (tapseldragging != SelDrag_none);
	
	taptracking = NO;
	tapseldragging = SelDrag_none;
	// leave taplastat intact
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(switchToTextSelection) object:nil];
	
	if (wasseldragging) {
		/* Text selection */
		[selectionview hideOutlineAnimated:YES];
		[self becomeFirstResponder];
		[self showSelectionMenu];
		return;
	}
	
	[self clearSelection];
	
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	if (now - taplastat > 0.75) {
		//NSLog(@"WGV: Touch took too long");
		[self clearTouchTracking];
		return;		
	}
	
	tapnumber++;
	taplastat = now;
	//NSLog(@"### tap %d!", tapnumber);

	IosGlkViewController *viewc = [IosGlkViewController singleton];
	GlkWindowView *winv = viewc.preferredInputWindow;

	/* If there is no input line (anywhere), ignore single-tap and double-tap. (Unless the game is over, in which case we post that dialog.) */
	if (!winv || !winv.inputfield) {
		if (viewc.vmexited)
			[viewc postGameOver];
		tapnumber = 0;
		return;
	}
	
	/* Otherwise, single-tap focuses the input line. */
	//### should really fling on double-tap
	if (tapnumber == 1) {
		if (![winv.inputfield isFirstResponder]) {
			tapnumber = 0;
			[winv.inputfield becomeFirstResponder];
		}
	}
	else {
		tapnumber = 0;
	}
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self clearTouchTracking];
}

- (BOOL) isAccessibilityElement {
	/* A UIAccessibilityContainer is never an element itself. */
	return NO;
}

- (NSInteger) accessibilityElementCount {
	/* Every line is an accessibility element. If an input field exists, it replaces one of the lines. */
	int count = lines.count;
	return count;
}

- (id) accessibilityElementAtIndex:(NSInteger)index {
	if (index >= lines.count)
		return nil;

	GlkWindowGridState *gridwin = (GlkWindowGridState *)winstate;
	if (self.inputholder && index == gridwin.cury)
		return self.inputholder;

	GlkStyledLine *vln = [lines objectAtIndex:index];
	return [vln accessElementInContainer:self];
}

- (NSInteger) indexOfAccessibilityElement:(id)element {
	if (!element)
		return NSNotFound;

	if (element == self.inputholder) {
		GlkWindowGridState *gridwin = (GlkWindowGridState *)winstate;
		return gridwin.cury;
	}

	if (![element isKindOfClass:[GlkAccStyledLine class]])
		return NSNotFound;
	GlkAccStyledLine *el = (GlkAccStyledLine *)element;
	if (!el.line)
		return NSNotFound;
	int index = el.line.index;
	if (index < 0 || index >= lines.count)
		return NSNotFound;
	return index;
}

@end

