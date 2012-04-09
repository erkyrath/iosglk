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
#import "GlkStream.h"
#import "GlkFileRef.h"
#import "GlkLibraryState.h"
#import "GlkWindowState.h"
#import "IosGlkLibDelegate.h"
#import "GlkUtilities.h"
#import "Geometry.h"
#import "StyleSet.h"
#include "glk.h"

@implementation GlkLibrary

#define SERIAL_VERSION (1)

@synthesize glkdelegate;
@synthesize windows;
@synthesize streams;
@synthesize filerefs;
@synthesize vmexited;
@synthesize rootwin;
@synthesize currentstr;
@synthesize bounds;
@synthesize geometrychanged;
@synthesize everythingchanged;
@synthesize specialrequest;
@synthesize filemanager;
@synthesize dispatch_register_obj;
@synthesize dispatch_unregister_obj;
@synthesize dispatch_register_arr;
@synthesize dispatch_unregister_arr;

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
		dispatch_register_arr = nil;
		dispatch_unregister_arr = nil;
				
		self.vmexited = NO;
		self.windows = [NSMutableArray arrayWithCapacity:8];
		self.streams = [NSMutableArray arrayWithCapacity:8];
		self.filerefs = [NSMutableArray arrayWithCapacity:8];
		self.rootwin = nil;
		self.currentstr = nil;
		geometrychanged = YES;
		everythingchanged = NO; /* not true at startup, only on refresh */
		
		self.specialrequest = nil;
		self.filemanager = [[[NSFileManager alloc] init] autorelease];
	}
	
	return self;
}

- (id) initWithCoder:(NSCoder *)decoder {
	int version = [decoder decodeIntForKey:@"version"];
	if (version <= 0 || version > SERIAL_VERSION)
		return nil;
	
	/* If the vm has exited, don't save the state! */
	vmexited = NO;
	
	bounds = [decoder decodeCGRectForKey:@"bounds"];
	geometrychanged = YES;
	everythingchanged = YES;
	
	self.windows = [decoder decodeObjectForKey:@"windows"];
	self.streams = [decoder decodeObjectForKey:@"streams"];
	self.filerefs = [decoder decodeObjectForKey:@"filerefs"];
	
	//### specialrequest: this really ought to be nil, right?

	self.filemanager = [[[NSFileManager alloc] init] autorelease];
	// skip the calendar fields, they're allocated as-needed

	NSNumber *rootwintag = [decoder decodeObjectForKey:@"rootwintag"];
	NSNumber *currentstrtag = [decoder decodeObjectForKey:@"currentstrtag"];
	
	tagCounter = 0;
	for (GlkWindow *win in windows) {
		win.library = self;
		glui32 tag = win.tag.intValue;
		if (tag > tagCounter)
			tagCounter = tag;
		if (rootwintag && [win.tag isEqualToNumber:rootwintag])
			self.rootwin = win;
	}
	for (GlkStream *str in streams) {
		str.library = self;
		glui32 tag = str.tag.intValue;
		if (tag > tagCounter)
			tagCounter = tag;
		if (currentstrtag && [str.tag isEqualToNumber:currentstrtag])
			self.currentstr = str;
	}
	for (GlkFileRef *fref in filerefs) {
		fref.library = self;
		glui32 tag = fref.tag.intValue;
		if (tag > tagCounter)
			tagCounter = tag;
	}

	for (GlkWindow *win in windows) {
		win.parent = (GlkWindowPair *)[self windowForTag:win.parenttag];
		win.stream = [self streamForTag:win.streamtag];
		if (win.echostreamtag)
			win.echostream = [self streamForTag:win.echostreamtag];
		
		//### patch up geometry.keystylesets! and pair.child1/2!
	}
	
	
	//### glkdelegate?
	//### dispatch_register_obj, et cetera...? (maybe these already work, because of the setting-up in gidispatch_set_object_registry()?)
	
	return self;
}

- (void) dealloc {
	NSLog(@"GlkLibrary dealloc %x", (unsigned int)self);
	if (singleton == self)
		singleton = nil;
	self.glkdelegate = nil;
	self.windows = nil;
	self.streams = nil;
	self.filerefs = nil;
	self.rootwin = nil;
	self.currentstr = nil;
	self.specialrequest = nil;
	self.filemanager = nil;
	if (utccalendar) {
		[utccalendar release];
		utccalendar = nil;
	}
	if (localcalendar) {
		[localcalendar release];
		localcalendar = nil;
	}
	[super dealloc];
}

- (void) encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeInt:SERIAL_VERSION forKey:@"version"];
	
	[encoder encodeCGRect:bounds forKey:@"bounds"];
	
	[encoder encodeObject:windows forKey:@"windows"];
	[encoder encodeObject:streams forKey:@"streams"];
	[encoder encodeObject:filerefs forKey:@"filerefs"];

	//### specialrequest: this really ought to be nil, right? fail if not

	if (rootwin)
		[encoder encodeObject:rootwin.tag forKey:@"rootwintag"];
	if (currentstr)
		[encoder encodeObject:currentstr.tag forKey:@"currentstrtag"];
}

/* If this app is an interpreter which handles many games, we need a way to keep their save files separate. We must return a string which is unique per game. (It's supplied by the delegate object.)
 
	If this app runs a single game, we don't care about this, so we always return "GameID".
 */
- (NSString *) gameId {
	NSString *gameid = [glkdelegate gameId];
	if (gameid)
		return gameid;
	return @"GameID";
}

/* Every Glk object (windows, streams, etc) needs a hashable tag. (The objects themselves don't make good hash keys.) The easiest solution is to pass out unique NSNumbers. 
	Note that these are *not* the glui32 ids seen by the Glulx VM. Those are generated separately, in the gi_dispa layer.
*/
- (NSNumber *) generateTag {
	tagCounter++;
	return [NSNumber numberWithInteger:tagCounter];
}

/* When the UI sees the screen change size, it calls this to tell the library. (On iOS, that happens only because of device rotation. Or the keyboard opening or closing. Or a phone call, probably. Okay, lots of reasons.) The UI also calls this if the window stylesets needs to change (because the player changed a preference).
 
	Returns YES if the geometry changed (in a way visible to the VM -- i.e., grid window rows/cols changed). This errs on the side of YES, however. (A one-pixel change probably won't change the window, but it will return YES anyhow.)
 
	This is called only at startup time and from the selectEvent loop.
*/
- (BOOL) setMetricsChanged:(BOOL)metricschanged bounds:(CGRect *)boxref {
	BOOL rearrange = NO;
	
	if (boxref) {
		/* The screen size changed. */
		CGRect box = *boxref;
		if (!CGRectEqualToRect(box, bounds)) {
			bounds = box;
			rearrange = YES;
			//NSLog(@"setMetrics: bounds now %@", StringFromRect(bounds));
		}
	}
	if (metricschanged) {
		/* The stylesets need to change. */
		for (GlkWindow *win in windows) {
			if (win.styleset)
				win.styleset = [StyleSet buildForWindowType:win.type rock:win.rock];
		}
		/* Pair windows need a little additional work. */
		for (GlkWindow *win in windows) {
			if (win.type == wintype_Pair) {
				Geometry *geometry = ((GlkWindowPair *)win).geometry;
				if (geometry && geometry.keytag) {
					GlkWindow *keywin = [self windowForTag:geometry.keytag];
					geometry.keystyleset = keywin.styleset;
				}
			}
		}
		rearrange = YES;
		//NSLog(@"setMetrics: metrics have changed");
	}
	
	if (!rearrange)
		return NO;
	
	NSLog(@"setMetrics: library rearrange, bounds now %@", StringFromRect(bounds));
	if (rootwin)
		[rootwin windowRearrange:bounds];
	return YES;
}

/* Locate the window matching a given tag. (Or nil, if no window matches or the tag is nil.) This isn't efficient, but it's not heavily used.
*/
- (GlkWindow *) windowForTag:(NSNumber *)tag {
	if (!tag)
		return nil;
	
	for (GlkWindow *win in windows) {
		if ([win.tag isEqualToNumber:tag])
			return win;
	}
	
	return nil;
}

- (void) dirtyAllData {
	everythingchanged = YES;
	geometrychanged = YES;
	for (GlkWindow *win in windows) {
		[win dirtyAllData];
	}
}

- (GlkLibraryState *) cloneState {
	GlkLibraryState *state = [[[GlkLibraryState alloc] init] autorelease];
	
	state.vmexited = vmexited;
	if (rootwin)
		state.rootwintag = rootwin.tag;
	
	/* This is not an immutable object, but only the UI will touch it until the event is complete, and then only the VM will touch it. Cope. */
	state.specialrequest = specialrequest;
	
	NSMutableArray *winstates = [NSMutableArray arrayWithCapacity:windows.count];
	for (GlkWindow *win in windows) {
		GlkWindowState *winstate = [win cloneState];
		winstate.library = state;
		[winstates addObject:winstate];
	}
	state.windows = winstates;
	
	state.geometrychanged = geometrychanged;
	geometrychanged = NO;
	state.everythingchanged = everythingchanged;
	everythingchanged = NO;
	
	return state;
}

/* Return a UTC Gregorian calendar object, allocating it if necessary.
*/
- (NSCalendar *) utccalendar {
	if (!utccalendar) {
		utccalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar]; // retain
		utccalendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
	}
	
	return utccalendar;
}

/* Return a local-time Gregorian calendar object, allocating it if necessary.
*/
- (NSCalendar *) localcalendar {
	if (!localcalendar) {
		localcalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar]; // retain
	}
	
	return localcalendar;
}

/* Display a warning. Really this should be a fatal error. Eventually it will be visible on the screen somehow, but at the moment it's just a console log message.
*/
+ (void) strictWarning:(NSString *)msg {
	NSLog(@"STRICT WARNING: %@", msg);
}

@end

