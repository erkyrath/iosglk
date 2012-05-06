/* GlkFrameView.m: Main view class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	GlkFrameView is the UIView which contains all of the Glk windows. (The GlkWindowViews are its children.) It is responsible for getting them all updated properly when the VM blocks for UI input.

	It's worth noting that all the content-y Glk windows have corresponding GlkWindowViews. But pair windows don't. They are abstractions which exist solely to calculate child window sizes.
*/

#import "GlkFrameView.h"
#import "IosGlkAppDelegate.h"
#import "IosGlkViewController.h"
#import "IosGlkLibDelegate.h"
#import "GlkWindowView.h"
#import "GlkWinGridView.h"
#import "GlkWinBufferView.h"
#import "CmdTextField.h"
#import "PopMenuView.h"
#import "InputMenuView.h"
#import "GlkAppWrapper.h"
#import "GlkLibraryState.h"
#import "GlkWindowState.h"
#import "Geometry.h"
#import "StyleSet.h"
#import "GlkUtilTypes.h"
#import "GlkUtilities.h"

@implementation GlkFrameView

@synthesize librarystate;
@synthesize windowviews;
@synthesize wingeometries;
@synthesize rootwintag;
@synthesize menuview;

- (id) initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	if (self) {
		NSLog(@"GlkFrameView allocated");
		self.windowviews = [NSMutableDictionary dictionaryWithCapacity:8];
		self.wingeometries = [NSMutableDictionary dictionaryWithCapacity:8];
		rootwintag = nil;
		
		cachedGlkBox = CGRectNull;
		
		inputmenumode = inputmenu_Palette;
	}
	return self;
}

- (void) dealloc {
	NSLog(@"GlkFrameView dealloc %x", (unsigned int)self);
	self.librarystate = nil;
	self.windowviews = nil;
	self.wingeometries = nil;
	self.rootwintag = nil;
	self.menuview = nil;
	[super dealloc];
}

- (GlkWindowView *) windowViewForTag:(NSNumber *)tag {
	return [windowviews objectForKey:tag];
}

/* Force all the windows to pick up new stylesets, and force all the windowviews to notice that fact.
 
	(Nitpickers will notice that it really happens the other way around! We update the views, and then notify the VM thread to update the windows.)
 */
- (void) updateWindowStyles {
	[self setNeedsLayout];
	for (NSNumber *tag in windowviews) {
		GlkWindowView *winv = [windowviews objectForKey:tag];
		StyleSet *styleset = [StyleSet buildForWindowType:winv.winstate.type rock:winv.winstate.rock];
		winv.winstate.styleset = styleset;
		winv.styleset = styleset;
		[winv uncacheLayoutAndStyles];
	}
	
	cachedGlkBox = CGRectNull;
	
	/* Now tell the VM thread to grab new stylesets, too. */
	[[GlkAppWrapper singleton] noteMetricsChanged];
}

- (void) layoutSubviews {
	CGRect keyboardbox = [IosGlkViewController singleton].keyboardbox;
	
	NSLog(@"frameview layoutSubviews to %@ (keyboard %@)", StringFromRect(self.bounds), StringFromSize(keyboardbox.size));
	
	IosGlkViewController *glkviewc = [IosGlkViewController singleton];
	
	CGRect box = self.bounds;
	
	/* Due to annoying startup inconsistencies, layoutSubviews can be called before the glkdelegate is set. If so, skip this step. */
	if (glkviewc.glkdelegate)
		box = [glkviewc.glkdelegate adjustFrame:box];
	
	if (keyboardbox.size.width > 0 && keyboardbox.size.height > 0) {
		CGFloat bottom = box.origin.y + box.size.height;
		CGRect rect = [self convertRect:keyboardbox fromView:nil];
		if (rect.origin.y < bottom) {
			bottom = rect.origin.y;
			box.size.height = bottom - box.origin.y;
		}
	}
	
	/* Only go through the layout mess if the view size really changed. */
	if (CGRectEqualToRect(cachedGlkBox, box))
		return;
	cachedGlkBox = box;

	if (menuview && menuview.vertalign < 0)
		[self removePopMenuAnimated:YES];

	if (rootwintag) {
		/* We perform all of the frame-size-changing in a zero-length animation. Yes, I tried using setAnimationsEnabled:NO to turn off the animations entirely. But that spiked the WinBufferView's scrollToBottom animation. Sorry -- it makes no sense to me either. */
		//NSLog(@"### root window exists; layout performing windowViewRearrange");
		[UIView beginAnimations:@"windowViewRearrange" context:nil];
		[UIView setAnimationDuration:0.0];
		/* This calls setNeedsLayout for all windows. */
		[self windowViewRearrange:rootwintag rect:box];
		[UIView commitAnimations];
	}
	
	/* Now tell the VM thread. */
	[[GlkAppWrapper singleton] setFrameSize:box];
}

/* Set all the window view sizes, based on their cached geometry information. Note that this does not touch the GlkLibrary structures at all -- that could be under modification by the VM thread.
 
	Calls setNeedsLayout for any window which changes size.
*/
- (void) windowViewRearrange:(NSNumber *)tag rect:(CGRect)box {
	GlkWindowView *winv = [windowviews objectForKey:tag];
	Geometry *geometry = [wingeometries objectForKey:tag];
	
	/* Exactly one of winv and geom should be set here. (geom for pair windows, winv for all others.) */
	if (winv && geometry)
		[NSException raise:@"GlkException" format:@"view and geometry for same window"];
	if (!winv && !geometry)
		[NSException raise:@"GlkException" format:@"neither view and geometry for same window"];
	
	if (winv) {
		if (!CGRectEqualToRect(winv.frame, box)) {
			winv.frame = box;
			[winv setNeedsLayout];
		}
	}
	else {
		CGRect box1;
		CGRect box2;
		NSNumber *ch1, *ch2;
		
		[geometry computeDivision:box for1:&box1 for2:&box2];

		if (!geometry.backward) {
			ch1 = geometry.child1tag;
			ch2 = geometry.child2tag;
		}
		else {
			ch1 = geometry.child2tag;
			ch2 = geometry.child1tag;
		}

		[self windowViewRearrange:ch1 rect:box1];
		[self windowViewRearrange:ch2 rect:box2];
	}
}

/* This is invoked when the frameview is reloaded. (Although not at startup time, because that load is manual.) We request a special out-of-sequence state update, with the special flag that means "we have no idea what's dirty, just feed us the lot".
 */
- (void) requestLibraryState:(GlkAppWrapper *)glkapp {
	NSLog(@"requestLibraryState");
	[glkapp requestViewUpdate];
}

/* This tells all the window views to get up to date with the new output in their data (GlkWindow) objects. If window views have to be created or destroyed (because GlkWindows have opened or closed), this does that too.
 
	Really, all the data is cloned -- we're getting a GlkLibraryState and a bunch of GlkWindowState objects. So we don't have to worry about colliding with the VM thread's work-in-progress.

	This is called from the glkviewc, but that's just a wrapper. The call originates from selectEvent in the app wrapper class.
*/
- (void) updateFromLibraryState:(GlkLibraryState *)library {
	NSLog(@"updateFromLibraryState (geometry %d, metrics %d)", library.geometrychanged, library.metricschanged);
	
	if (!library)
		[NSException raise:@"GlkException" format:@"updateFromLibraryState: no library"];
	
	self.librarystate = library;
	// vmexited is cached in the viewc also.
	
	/* Build a list of windowviews which need to be closed. */
	NSMutableDictionary *closed = [NSMutableDictionary dictionaryWithDictionary:windowviews];
	for (GlkWindowState *win in library.windows) {
		[closed removeObjectForKey:win.tag];
	}

	/* And close them. */
	for (NSNumber *tag in closed) {
		GlkWindowView *winv = [closed objectForKey:tag];
		[winv removeFromSuperview];
		winv.inputfield = nil; /* detach this now */
		winv.inputholder = nil;
		[windowviews removeObjectForKey:tag];
	}
	
	closed = nil;
	
	/* If there are any new windows, create windowviews for them. */
	for (GlkWindowState *win in library.windows) {
		if (win.type != wintype_Pair && ![windowviews objectForKey:win.tag]) {
			IosGlkViewController *glkviewc = [IosGlkViewController singleton];
			//NSLog(@"### creating new winview, box %@", StringFromRect(win.bbox));
			GlkWindowView *winv = nil;
			switch (win.type) {
				case wintype_TextBuffer:
					if (glkviewc.glkdelegate)
						winv = [glkviewc.glkdelegate viewForBufferWindow:win frame:win.bbox];
					if (!winv)
						winv = [[[GlkWinBufferView alloc] initWithWindow:win frame:win.bbox] autorelease];
					break;
				case wintype_TextGrid:
					if (glkviewc.glkdelegate)
						winv = [glkviewc.glkdelegate viewForGridWindow:win frame:win.bbox];
					if (!winv)
						winv = [[[GlkWinGridView alloc] initWithWindow:win frame:win.bbox] autorelease];
					break;
				default:
					[NSException raise:@"GlkException" format:@"no windowview class for this window"];
			}
			[windowviews setObject:winv forKey:win.tag];
			[self addSubview:winv];
		}
	}
	
	/* If the window geometry has changed (windows created, deleted, or arrangement-set) then rebuild the geometry cache. */
	if (library.geometrychanged || library.metricschanged) {
		//NSLog(@"Recaching window geometries");
		self.rootwintag = library.rootwintag;
		[wingeometries removeAllObjects];
		for (GlkWindowState *win in library.windows) {
			if (win.type == wintype_Pair) {
				GlkWindowPairState *pairwin = (GlkWindowPairState *)win;
				[wingeometries setObject:pairwin.geometry forKey:win.tag];
			}
		}
	}
	
	if (rootwintag) {
		/* We perform all of the frame-size-changing in a zero-length animation. Yes, I tried using setAnimationsEnabled:NO to turn off the animations entirely. But that spiked the WinBufferView's scrollToBottom animation. Sorry -- it makes no sense to me either. */
		//NSLog(@"### root window exists; update performing windowViewRearrange");
		[UIView beginAnimations:@"windowViewRearrange" context:nil];
		[UIView setAnimationDuration:0.0];
		/* This calls setNeedsLayout for all windows. */
		[self windowViewRearrange:rootwintag rect:cachedGlkBox];
		[UIView commitAnimations];
	}
	
	/*
	NSLog(@"frameview has %d windows:", windowviews.count);
	for (NSNumber *tag in windowviews) {
		NSLog(@"... %d: %@", [tag intValue], [windowviews objectForKey:tag]);
		//GlkWindowView *winv = [windowviews objectForKey:tag];
		//NSLog(@"... win is %@", winv.win);
	}
	*/

	/* Now go through all the window views, and tell them to update to match their windows. */
	for (GlkWindowState *win in library.windows) {
		GlkWindowView *winv = [windowviews objectForKey:win.tag];
		if (winv)
			winv.winstate = win;
	}
	for (NSNumber *tag in windowviews) {
		GlkWindowView *winv = [windowviews objectForKey:tag];
		[winv updateFromWindowState];
		[winv updateFromWindowInputs];
	}
	
	/* Slightly awkward, but mostly right: if voiceover is on, speak the most recent buffer window update. */
	if (UIAccessibilityIsVoiceOverRunning()) {
		for (GlkWindowState *win in library.windows) {
			if ([win isKindOfClass:[GlkWindowBufferState class]]) {
				GlkWindowBufferState *bufwin = (GlkWindowBufferState *)win;
				NSArray *lines = bufwin.lines;
				if (lines && lines.count && bufwin.linesdirtyto > bufwin.linesdirtyfrom) {
					NSMutableArray *arr = [NSMutableArray arrayWithCapacity:(bufwin.linesdirtyto - bufwin.linesdirtyfrom)];
					for (int ix=bufwin.linesdirtyfrom; ix<bufwin.linesdirtyto; ix++) {
						GlkStyledLine *vln = [lines objectAtIndex:ix];
						NSString *str = vln.concatLine;
						if (str.length)
							[arr addObject:vln.concatLine];
					}
					if (arr.count) {
						NSString *speakbuffer = [arr componentsJoinedByString:@"\n"];
						//NSLog(@"### speak: %@", speakbuffer);
						UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, speakbuffer);
						break;
					}
				}
			}
		}
	}
	
	/* And now, if there's a special prompt going on, fill the screen with it. */
	if (library.specialrequest)
		[[IosGlkAppDelegate singleton].glkviewc displayModalRequest:library.specialrequest];
}

/* Query the main thread about what's in a particular window's input line. The VM thread calls this when it cancels line input and needs to know what in the input buffer.

	This is invoked in the main thread, by the VM thread, which is waiting on the result. We're safe from deadlock because the VM thread can't be in glk_select(); it can't be holding the iowait lock, and it can't get into the code path that rearranges the view structure.
*/
- (void) editingTextForWindow:(GlkTagString *)tagstring {
	GlkWindowView *winv = [windowviews objectForKey:tagstring.tag];
	if (!winv)
		return;
	
	CmdTextField *textfield = winv.inputfield;
	if (!textfield)
		return;
		
	NSString *text = textfield.text;
	if (!text)
		return;
	
	tagstring.str = [NSString stringWithString:text];
}

- (void) postPopMenu:(PopMenuView *)menu {
	if (menuview) {
		[self removePopMenuAnimated:YES];
	}
	
	self.menuview = menu;
	[[NSBundle mainBundle] loadNibNamed:@"PopBoxView" owner:menuview options:nil];
	
	NSString *decorname = menu.bottomDecorNib;
	if (decorname) {
		[[NSBundle mainBundle] loadNibNamed:decorname owner:menuview options:nil];
		CGRect menubox = menuview.frameview.bounds;
		CGRect decorbox = menuview.decor.bounds;
		CGRect contentbox = menuview.content.frame;
		contentbox.size.height -= decorbox.size.height;
		menuview.content.frame = contentbox;
		decorbox.origin.y = menubox.origin.y + menubox.size.height - decorbox.size.height;
		decorbox.origin.x = menubox.origin.x;
		decorbox.size.width = menubox.size.width;
		menuview.decor.frame = decorbox;
		if (menuview.faderview)
			[menuview.frameview insertSubview:menuview.decor belowSubview:menuview.faderview];
		else
			[menuview.frameview addSubview:menuview.decor];
	}

	menuview.framemargins = UIEdgeInsetsRectDiff(menuview.frameview.frame, menuview.content.frame);
	[menuview loadContent];
	
	[menuview addSubview:menuview.frameview];
	if ([IosGlkAppDelegate animblocksavailable]) {
		menuview.alpha = 0;
		[self addSubview:menuview];
		[UIView animateWithDuration:0.1 
						 animations:^{ menuview.alpha = 1; } ];
	}
	else {
		[self addSubview:menuview];
	}
}

- (void) removePopMenuAnimated:(BOOL)animated {
	if (!menuview)
		return;
	
	[menuview willRemove];
	
	if (animated && [IosGlkAppDelegate animblocksavailable]) {
		UIView *oldview = menuview;
		[UIView animateWithDuration:0.25 
						 animations:^{ oldview.alpha = 0; } 
						 completion:^(BOOL finished) { [oldview removeFromSuperview]; } ];
	}
	else {
		[menuview removeFromSuperview];
	}
	self.menuview = nil;
}

@end


