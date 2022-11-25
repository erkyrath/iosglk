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
#import "GlkWindowViewUIState.h"
#import "CmdTextField.h"
#import "PopMenuView.h"
#import "InputMenuView.h"
#import "GlkAppWrapper.h"
#import "GlkLibraryState.h"
#import "GlkWindowState.h"
#import "Geometry.h"
#import "StyleSet.h"
#import "GlkAccessTypes.h"
#import "GlkUtilTypes.h"
#import "GlkUtilities.h"

@implementation GlkFrameView

+ (BOOL) supportsSecureCoding {
    return YES;
}

- (instancetype) initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	if (self) {
		self.windowviews = [NSMutableDictionary dictionaryWithCapacity:8];
		self.wingeometries = [NSMutableDictionary dictionaryWithCapacity:8];
		_rootwintag = nil;
		
		cachedGlkBox = CGRectNull;
		cachedGlkBoxInvalid = YES;
		
		inputmenumode = inputmenu_Palette;
	}
	return self;
}


- (GlkWindowView *) windowViewForTag:(NSNumber *)tag {
	return _windowviews[tag];
}

/* Force all the windows to pick up new stylesets, and force all the windowviews to notice that fact.
 
	(Nitpickers will notice that it really happens the other way around! We update the views, and then notify the VM thread to update the windows.)
 */
- (void) updateWindowStyles {
	[self setNeedsLayout];
	for (NSNumber *tag in _windowviews) {
		GlkWindowView *winv = _windowviews[tag];
		StyleSet *styleset = [StyleSet buildForWindowType:winv.winstate.type rock:winv.winstate.rock];
		winv.winstate.styleset = styleset;
		winv.styleset = styleset;
		[winv uncacheLayoutAndStyles];
	}
	
	/* Mark cachedGlkBox as invalid, but leave the actual rectangle value. If a updateFromLibraryState sneaks in before our next layoutSubviews, we want to have something to work with. */
	cachedGlkBoxInvalid = YES;
	
	/* Now tell the VM thread to grab new stylesets, too. */
	[[GlkAppWrapper singleton] noteMetricsChanged];
}

- (void) updateInputTraits {
	for (NSNumber *tag in _windowviews) {
		GlkWindowView *winv = _windowviews[tag];
		if (winv.inputfield)
			[winv.inputfield adjustInputTraits];
	}
}

- (void) layoutSubviews {
    /* FIXME: If the player selects text while the keyboard is visible, this will hide the keyboard and
    call this, which will issue an arrange event. If we are in a help menu and showing help text, this will
     usually throw us back to the menu. The same thing happens if we change orientation while showing help text. */
	CGRect keyboardbox = [IosGlkViewController singleton].keyboardbox;
	
	//NSLog(@"frameview layoutSubviews to %@ (keyboard %@)", StringFromRect(self.bounds), StringFromSize(keyboardbox.size));
	
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
	
	/* Only go through the layout mess if the view size really changed. Or the invalid flag is set. */
	if ((!cachedGlkBoxInvalid) && CGRectEqualToRect(cachedGlkBox, box)) {
		return;
	}

    BOOL onlyHeightChanged = ([self hasStandardGlkSetup] && cachedGlkBox.size.width == box.size.width);

	cachedGlkBox = box;
	cachedGlkBoxInvalid = NO;

	if (_menuview && _menuview.vertalign < 0)
		[self removePopMenuAnimated:YES];

	if (_rootwintag) {
		/* We perform all of the frame-size-changing in a zero-length animation. Yes, I tried using setAnimationsEnabled:NO to turn off the animations entirely. But that spiked the WinBufferView's scrollToBottom animation. Sorry -- it makes no sense to me either. */
		//NSLog(@"### root window exists; layout performing windowViewRearrange, box %@", StringFromRect(box));
        GlkFrameView __weak *weakSelf = self;
        [UIView animateWithDuration:0.0 animations:^{ [weakSelf windowViewRearrange:weakSelf.rootwintag rect:box]; } ];
	}
	
	/* Now tell the VM thread. */

    if (!onlyHeightChanged)
        [[GlkAppWrapper singleton] setFrameSize:box];
}

/* Set all the window view sizes, based on their cached geometry information. Note that this does not touch the GlkLibrary structures at all -- that could be under modification by the VM thread.
 
	Calls setNeedsLayout for any window which changes size.
*/
- (void) windowViewRearrange:(NSNumber *)tag rect:(CGRect)box {
    if (isnan(box.origin.x) || isinf(box.origin.x))
        return;
	GlkWindowView *winv = _windowviews[tag];
	Geometry *geometry = _wingeometries[tag];
	
	/* Exactly one of winv and geom should be set here. (geom for pair windows, winv for all others.) */
	if (winv && geometry)
		[NSException raise:@"GlkException" format:@"view and geometry for same window"];
	if (!winv && !geometry)
		[NSException raise:@"GlkException" format:@"neither view and geometry for same window"];
	
	if (winv) {
		IosGlkViewController *glkviewc = [IosGlkViewController singleton];
		UIEdgeInsets viewmargin = UIEdgeInsetsZero;
		if (glkviewc.glkdelegate)
			viewmargin = [glkviewc.glkdelegate viewMarginForWindow:winv.winstate rect:box framebounds:self.bounds];
		CGRect viewbox = RectApplyingEdgeInsets(box, UIEdgeInsetsInvert(viewmargin));
		if (!(CGRectEqualToRect(winv.frame, viewbox) && UIEdgeInsetsEqualToEdgeInsets(winv.viewmargin, viewmargin))) {
			winv.frame = viewbox;
			winv.viewmargin = viewmargin;
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
	[glkapp requestViewUpdate];
}

/* This tells all the window views to get up to date with the new output in their data (GlkWindow) objects. If window views have to be created or destroyed (because GlkWindows have opened or closed), this does that too.
 
	Really, all the data is cloned -- we're getting a GlkLibraryState and a bunch of GlkWindowState objects. So we don't have to worry about colliding with the VM thread's work-in-progress.

	This is called from the glkviewc, but that's just a wrapper. The call originates from selectEvent in the app wrapper class.
*/
- (void) updateFromLibraryState:(GlkLibraryState *)library {
	//NSLog(@"updateFromLibraryState (geometry %d, metrics %d)", library.geometrychanged, library.metricschanged);
	
	if (!library)
		[NSException raise:@"GlkException" format:@"updateFromLibraryState: no library"];
	
	self.librarystate = library;
	// vmexited is cached in the viewc also.
	
	/* Build a list of windowviews which need to be closed. */
	NSMutableDictionary *closed = [NSMutableDictionary dictionaryWithDictionary:_windowviews];
	for (GlkWindowState *win in library.windows) {
		[closed removeObjectForKey:win.tag];
	}

	/* And close them. */
	for (NSNumber *tag in closed) {
		GlkWindowView *winv = closed[tag];
		[winv removeFromSuperview];
		winv.inputfield = nil; /* detach this now */
		winv.inputholder = nil;
		[_windowviews removeObjectForKey:tag];
	}
	
	closed = nil;
	
	/* If there are any new windows, create windowviews for them. */
	for (GlkWindowState *win in library.windows) {
		if (win.type != wintype_Pair && !_windowviews[win.tag]) {
			IosGlkViewController *glkviewc = [IosGlkViewController singleton];
			UIEdgeInsets viewmargin = UIEdgeInsetsZero;
			if (glkviewc.glkdelegate)
				viewmargin = [glkviewc.glkdelegate viewMarginForWindow:win rect:win.bbox framebounds:self.bounds];
			CGRect viewbox = RectApplyingEdgeInsets(win.bbox, UIEdgeInsetsInvert(viewmargin));
			//NSLog(@"### creating new winview, win box %@, view box %@", StringFromRect(win.bbox), StringFromRect(viewbox));
			GlkWindowView *winv = nil;
			switch (win.type) {
				case wintype_TextBuffer:
					if (glkviewc.glkdelegate)
						winv = [glkviewc.glkdelegate viewForBufferWindow:win frame:viewbox margin:viewmargin];
					if (!winv)
						winv = [[GlkWinBufferView alloc] initWithWindow:win frame:viewbox margin:viewmargin];
					break;
				case wintype_TextGrid:
					if (glkviewc.glkdelegate)
						winv = [glkviewc.glkdelegate viewForGridWindow:win frame:viewbox margin:viewmargin];
					if (!winv)
						winv = [[GlkWinGridView alloc] initWithWindow:win frame:viewbox margin:viewmargin];
					break;
				default:
					[NSException raise:@"GlkException" format:@"no windowview class for this window"];
			}
			_windowviews[win.tag] = winv;
			[self addSubview:winv];
		}
	}
	
	/* If the window geometry has changed (windows created, deleted, or arrangement-set) then rebuild the geometry cache. */
	if (library.geometrychanged || library.metricschanged) {
		//NSLog(@"Recaching window geometries");
		self.rootwintag = library.rootwintag;
		[_wingeometries removeAllObjects];
		for (GlkWindowState *win in library.windows) {
			if (win.type == wintype_Pair) {
				GlkWindowPairState *pairwin = (GlkWindowPairState *)win;
				_wingeometries[win.tag] = pairwin.geometry;
			}
		}
	}
	
	if (_rootwintag) {
		/* We perform all of the frame-size-changing in a zero-length animation. Yes, I tried using setAnimationsEnabled:NO to turn off the animations entirely. But that spiked the WinBufferView's scrollToBottom animation. Sorry -- it makes no sense to me either. */
		//NSLog(@"### root window exists; update performing windowViewRearrange, cachedGlkBox %@ (valid %d)", StringFromRect(cachedGlkBox), cachedGlkBoxInvalid);
        GlkFrameView __weak *weakSelf = self;
        [UIView animateWithDuration:0.0 animations:^{
            GlkFrameView *strongSelf = weakSelf;
            if (strongSelf)
                [strongSelf windowViewRearrange:strongSelf.rootwintag rect:strongSelf->cachedGlkBox];
        }];
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
		GlkWindowView *winv = _windowviews[win.tag];
		if (winv)
			winv.winstate = win;
	}
	for (NSNumber *tag in _windowviews) {
		GlkWindowView *winv = _windowviews[tag];
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
	GlkWindowView *winv = _windowviews[tagstring.tag];
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
	if (_menuview) {
		[self removePopMenuAnimated:YES];
	}
	
	self.menuview = menu;
	[[NSBundle mainBundle] loadNibNamed:@"PopBoxView" owner:_menuview options:nil];
	
	NSString *decorname = menu.bottomDecorNib;
	if (decorname) {
		[[NSBundle mainBundle] loadNibNamed:decorname owner:_menuview options:nil];
		CGRect menubox = _menuview.frameview.bounds;
		CGRect decorbox = _menuview.decor.bounds;
		CGRect contentbox = _menuview.content.frame;
		contentbox.size.height -= decorbox.size.height;
		_menuview.content.frame = contentbox;
		decorbox.origin.y = menubox.origin.y + menubox.size.height - decorbox.size.height;
		decorbox.origin.x = menubox.origin.x;
		decorbox.size.width = menubox.size.width;
		_menuview.decor.frame = decorbox;
		if (_menuview.faderview)
			[_menuview.frameview insertSubview:_menuview.decor belowSubview:_menuview.faderview];
		else
			[_menuview.frameview addSubview:_menuview.decor];
	}

	_menuview.framemargins = UIEdgeInsetsRectDiff(_menuview.frameview.frame, _menuview.content.frame);
	[_menuview loadContent];
	
	[_menuview addSubview:_menuview.frameview];
	if (/* DISABLES CODE */ (true)) {
		_menuview.alpha = 0;
		[self addSubview:_menuview];
        GlkFrameView __weak *weakSelf = self;
		[UIView animateWithDuration:0.1 
                         animations:^{ weakSelf.menuview.alpha = 1; } ];
	}
	else {
		[self addSubview:_menuview];
	}
}

- (void) removePopMenuAnimated:(BOOL)animated {
	if (!_menuview)
		return;
	
	[_menuview willRemove];
	
	if (animated) {
		UIView *oldview = _menuview;
		[UIView animateWithDuration:0.25 
						 animations:^{ oldview.alpha = 0; } 
						 completion:^(BOOL finished) { [oldview removeFromSuperview]; } ];
	}
	else {
		[_menuview removeFromSuperview];
	}
	self.menuview = nil;
}

- (NSDictionary *)getCurrentViewStates {
    NSMutableDictionary *states = [[NSMutableDictionary alloc] initWithCapacity:_windowviews.count];
    for (NSNumber *key in _windowviews.allKeys) {
        GlkWindowViewUIState *state = [[GlkWindowViewUIState alloc] initWithGlkWindowView:_windowviews[key]];
        states[key] = [state dictionaryFromState];
    }
    return @{ @"GlkWindowViewStates" : states };
}

- (BOOL) updateWithUIStates:(NSDictionary *)states {
    BOOL found = NO;
    for (NSNumber *tag in states.allKeys) {
        GlkWindowView *view = _windowviews[tag];
        if (view) {
            [view updateFromUIState:states[tag]];
            found = YES;
        } else {
            NSLog(@"Could not find view with tag %@", tag);
        }
    }
    if (!found) {
        NSLog(@"Error! Missing window views");
    }
    return found;
}

- (void) preserveScrollPositions {
    for (GlkWindowView *view in _windowviews.allValues) {
        if ([view isKindOfClass:[GlkWinBufferView class]]) {
            [(GlkWinBufferView *)view preserveScrollPosition];
        }
    }

}

- (void) restoreScrollPositions {
    _inOrientationAnimation = NO;
    for (GlkWindowView *view in _windowviews.allValues) {
        if ([view isKindOfClass:[GlkWinBufferView class]]) {
            [(GlkWinBufferView *)view restoreScrollPosition];
        }
    }
}

// FIXME: This is supposed to check if we have the standard layout with a grid status bar plus buffer main window, but it doesn't really currently. Its main use is that if it is true, we do not send rearrange events to the VM thread when the keyboard is shown or hidden, as this breaks the help menu.
- (BOOL) hasStandardGlkSetup {
    NSArray *views = _windowviews.allValues;
    return (views.count == 2 && ([views.firstObject isKindOfClass:[GlkWinBufferView class]] || [views.lastObject isKindOfClass:[GlkWinBufferView class]]));
}

@end


