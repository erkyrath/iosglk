/* GlkLibrary.m: Library context object
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	The GlkLibrary class contains all the state for the running Glk display. (The API doesn't currently allow multiple Glk contexts, but if it did, each context would be a GlkLibrary. As it is, this is a singleton class, and many Glk functions call [GlkLibrary singleton] to get the reference.)

	Look here for the list of open windows, the list of open streams, the current root window, and so on.
*/

#import "GlkLibrary.h"
#import "GlkWindow.h"
#include "GlkUtilities.h"
#include "glk.h"

@implementation GlkLibrary

@synthesize windows;
@synthesize streams;
@synthesize rootwin;
@synthesize currentstr;
@synthesize bounds;
@synthesize dispatch_register_obj;
@synthesize dispatch_unregister_obj;

static GlkLibrary *singleton = nil;

+ (GlkLibrary *) singleton {
	return singleton;
}

- (id) init {
	self = [super init];
	
	if (self) {
		if (singleton)
			[NSException raise:@"GlkException" format:@"cannot create two GlkLibrary objects"];
		singleton = self;
		
		tagCounter = 0;
		dispatch_register_obj = nil;
		dispatch_unregister_obj = nil;
		
		self.windows = [NSMutableArray arrayWithCapacity:8];
		self.streams = [NSMutableArray arrayWithCapacity:8];
		self.rootwin = nil;
		self.currentstr = nil;
	}
	
	return self;
}

- (void) dealloc {
	NSLog(@"GlkLibrary dealloc %x", self);
	if (singleton == self)
		singleton = nil;
	self.windows = nil;
	self.streams = nil;
	self.rootwin = nil;
	self.currentstr = nil;
	[super dealloc];
}

/* Every Glk object (windows, streams, etc) needs a hashable tag. (The objects themselves don't make good hash keys.) The easiest solution is to pass out unique NSNumbers. 
	Note that these are *not* the glui32 ids seen by the Glulx VM. Those are generated separately, in the gi_dispa layer.
*/
- (NSNumber *) newTag {
	tagCounter++;
	return [NSNumber numberWithInteger:tagCounter];
}

/* When the UI sees the screen change size, it calls this to tell the library. (On iOS, that happens only because of device rotation.) Returns YES if the bounds changed.
	Do not call this when the VM thread is live. (Wait until it blocks.)
*/
- (BOOL) setMetrics:(CGRect)box {
	if (CGRectEqualToRect(box, bounds))
		return NO;
	
	bounds = box;
	NSLog(@"library metrics now %@", StringFromRect(bounds));
	if (rootwin)
		[rootwin windowRearrange:bounds];
	return YES;
}

/* Display a warning. Really this should be a fatal error. Eventually it will be visible on the screen somehow, but at the moment it's just a console log message.
*/
+ (void) strictWarning:(NSString *)msg {
	NSLog(@"strict warning: %@", msg);
}

@end

