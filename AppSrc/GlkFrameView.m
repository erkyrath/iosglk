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
#import "GlkLibrary.h"
#import "GlkWindow.h"
#import "Geometry.h"
#import "StyleSet.h"
#import "GlkUtilTypes.h"
#import "GlkUtilities.h"

@implementation GlkFrameView

@synthesize windowviews;
@synthesize wingeometries;
@synthesize rootwintag;
@synthesize menuview;

- (id) initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	if (self) {
		NSLog(@"GlkFrameView allocated");
		keyboardBox = CGRectZero;
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
	self.windowviews = nil;
	self.wingeometries = nil;
	self.rootwintag = nil;
	self.menuview = nil;
	[super dealloc];
}

- (GlkWindowView *) windowViewForTag:(NSNumber *)tag {
	return [windowviews objectForKey:tag];
}

- (CGRect) keyboardBox {
	return keyboardBox;
}

//### move keyboardBox to the viewc? (So that it's not lost if the frameview is dropped)
- (void) setKeyboardBox:(CGRect)val {
	keyboardBox = val;
	//NSLog(@"### setKeyboardHeight calling setNeedsLayout");
	[self setNeedsLayout];
}

/* Force all the windows to pick up new stylesets, and then force all the windowviews to notice that fact.
 
	This leaves the windowview stylesets detached from the window stylesets, which is irritating, but not a real problem (since stylesets are immutable).
 */
- (void) updateWindowStyles {
	[self setNeedsLayout];
	for (NSNumber *tag in windowviews) {
		GlkWindowView *winv = [windowviews objectForKey:tag];
		winv.styleset = [StyleSet buildForWindowType:winv.win.type rock:winv.win.rock];
		[winv uncacheLayoutAndStyles];
	}
	
	cachedGlkBox = CGRectNull;
	
	//### skip for color-only changes?
	/* Now tell the VM thread. */
	[[GlkAppWrapper singleton] noteMetricsChanged];
}

- (void) layoutSubviews {
	NSLog(@"frameview layoutSubviews to %@ (keyboard %@)", StringFromRect(self.bounds), StringFromSize(keyboardBox.size));
	
	IosGlkViewController *glkviewc = [IosGlkViewController singleton];
	
	CGRect box = self.bounds;
	
	/* Due to annoying startup inconsistencies, layoutSubviews can be called before the glkdelegate is set. If so, skip this step. */
	if (glkviewc.glkdelegate)
		box = [glkviewc.glkdelegate adjustFrame:box];
	
	if (keyboardBox.size.width > 0 && keyboardBox.size.height > 0) {
		CGFloat bottom = box.origin.y + box.size.height;
		CGRect rect = [self convertRect:keyboardBox fromView:glkviewc.view];
		if (rect.origin.y < bottom) {
			bottom = rect.origin.y;
			box.size.height = bottom - box.origin.y;
		}
	}
	
	/* Only go through the layout mess if the view size really changed. */
	if (CGRectEqualToRect(cachedGlkBox, box))
		return;
	cachedGlkBox = box;

	if (menuview && !menuview.belowbutton)
		[self removePopMenuAnimated:YES];

	if (rootwintag) {
		/* We perform all of the frame-size-changing in a zero-length animation. Yes, I tried using setAnimationsEnabled:NO to turn off the animations entirely. But that spiked the WinBufferView's scrollToBottom animation. Sorry -- it makes no sense to me either. */
		[UIView beginAnimations:@"windowViewRearrange" context:nil];
		[UIView setAnimationDuration:0.0];
		[self windowViewRearrange:rootwintag rect:box];
		[UIView commitAnimations];
	}
	
	/* Now tell the VM thread. */
	[[GlkAppWrapper singleton] setFrameSize:box];
}

/* Set all the window view sizes, based on their cached geometry information. Note that this does not touch the GlkLibrary structures at all -- that could be under modification by the VM thread.

	(Small exception: this code looks at the Geometry objects, which are shared with GlkLibrary. That's okay because Geometry objects are immutable.)
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
		//NSLog(@"### setting frame for winview %@", winv);
		winv.frame = box;
		[winv setNeedsLayout];
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

	Called from selectEvent in the app wrapper class. This queries the GlkLibrary data structures. (It should be safe to do that, because the VM thread is now waiting for input, and it won't get any until we've updated our windows with new input fields and such.)
*/
- (void) updateFromLibraryState:(GlkLibrary *)library {
	NSLog(@"updateFromLibraryState: %@", StringFromRect(library.bounds));
	
	if (!library)
		[NSException raise:@"GlkException" format:@"updateFromLibraryState: no library"];
	
	/* Build a list of windowviews which need to be closed. */
	NSMutableDictionary *closed = [NSMutableDictionary dictionaryWithDictionary:windowviews];
	for (GlkWindow *win in library.windows) {
		[closed removeObjectForKey:win.tag];
	}

	/* And close them. */
	for (NSNumber *tag in closed) {
		GlkWindowView *winv = [closed objectForKey:tag];
		[winv removeFromSuperview];
		winv.inputfield = nil; /* detach this now */
		winv.inputholder = nil;
		//### probably should detach all subviews
		[windowviews removeObjectForKey:tag];
	}
	
	closed = nil;
	
	/* If there are any new windows, create windowviews for them. */
	for (GlkWindow *win in library.windows) {
		if (win.type != wintype_Pair && ![windowviews objectForKey:win.tag]) {
			IosGlkViewController *glkviewc = [IosGlkViewController singleton];
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
	if (library.geometrychanged) {
		//NSLog(@"Recaching window geometries");
		library.geometrychanged = NO;
		if (library.rootwin)
			self.rootwintag = library.rootwin.tag;
		else
			self.rootwintag = nil;
		[wingeometries removeAllObjects];
		for (GlkWindowPair *win in library.windows) {
			if (win.type == wintype_Pair) {
				Geometry *geom = [[win.geometry copy] autorelease];
				[wingeometries setObject:geom forKey:win.tag];
			}
		}
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
	for (NSNumber *tag in windowviews) {
		GlkWindowView *winv = [windowviews objectForKey:tag];
		[winv updateFromWindowState];
		[winv updateFromWindowInputs];
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
	[[IosGlkAppDelegate singleton].glkviewc buildPopMenu:menuview];

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


