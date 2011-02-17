/* GlkFrameView.m: Main view class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	GlkFrameView is the UIView which contains all of the Glk windows. (The GlkWindowViews are its children.) It is responsible for getting them all updated properly when the VM blocks for UI input.

	It's worth noting that all the content-y Glk windows have corresponding GlkWindowViews. But pair windows don't. They are abstractions which exist solely to calculate child window sizes.
*/

#import "GlkFrameView.h"
#import "GlkWindowView.h"
#import "GlkAppWrapper.h"
#import "GlkLibrary.h"
#import "GlkWindow.h"
#include "GlkUtilities.h"

@implementation GlkFrameView

@synthesize windowviews;

- (void) awakeFromNib {
	[super awakeFromNib];
	NSLog(@"GlkFrameView awakened, bounds %@", StringFromRect(self.bounds));
	
	self.windowviews = [NSMutableDictionary dictionaryWithCapacity:8];
}

- (void) dealloc {
	self.windowviews = nil;
	[super dealloc];
}

- (void) layoutSubviews {
	NSLog(@"frameview layoutSubviews");
	
	[[GlkAppWrapper singleton] setFrameSize:self.bounds];
}

/* This tells all the window views to get up to date with the new output in their data (GlkWindow) objects. If window views have to be created or destroyed (because GlkWindows have opened or closed), this does that too.
*/
- (void) updateFromLibraryState:(GlkLibrary *)library {
	NSLog(@"updateFromLibraryState");
	
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
		[windowviews removeObjectForKey:tag];
	}
	
	closed = nil;
	
	/* If there are any new windows, create windowviews for them. */
	for (GlkWindow *win in library.windows) {
		if (win.type != wintype_Pair && ![windowviews objectForKey:win.tag]) {
			GlkWindowView *winv = [GlkWindowView viewForWindow:win];
			[windowviews setObject:winv forKey:win.tag];
			[self addSubview:winv];
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
	}
}

/* This tells all the window views to get up to date with the sizes of their GlkWindows. The library's setMetrics must already have been called, to get the GlkWindow sizes set right.
*/
- (void) updateFromLibrarySize:(GlkLibrary *)library {
	NSLog(@"updateFromLibrarySize");
	
	for (NSNumber *tag in windowviews) {
		GlkWindowView *winv = [windowviews objectForKey:tag];
		[winv updateFromWindowSize];
	}
	[[GlkAppWrapper singleton] acceptEventType:evtype_Arrange window:nil val1:0 val2:0];
}


@end
