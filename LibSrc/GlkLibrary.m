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
@synthesize timerinterval;
@synthesize bounds;
@synthesize geometrychanged;
@synthesize metricschanged;
@synthesize everythingchanged;
@synthesize specialrequest;
@synthesize filemanager;
@synthesize tagCounter;
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
		timerinterval = 0;
		geometrychanged = YES;
		metricschanged = YES;
		everythingchanged = NO; /* not true at startup, only on refresh */
		
		self.specialrequest = nil;
		self.filemanager = [[[NSFileManager alloc] init] autorelease];
	}
	
	return self;
}

- (id) initWithCoder:(NSCoder *)decoder {
	/* It is important to remember that a GlkLibrary which is deserialized through this function will *not* be installed straight into service. Instead, it will be imported into the *real* library via the updateFromLibrary method. This frees us from some consistency-check hassle.
	 
		Also, it means that a library created via this path is never the singleton.
	 */
	
	int version = [decoder decodeIntForKey:@"version"];
	if (version <= 0 || version > SERIAL_VERSION)
		return nil;
	
	/* If the vm has exited, we shouldn't have saved the state! */
	vmexited = NO;
	self.specialrequest = nil;
	
	bounds = [decoder decodeCGRectForKey:@"bounds"];
	geometrychanged = YES;
	metricschanged = YES;
	everythingchanged = YES;
	
	self.windows = [decoder decodeObjectForKey:@"windows"];
	self.streams = [decoder decodeObjectForKey:@"streams"];
	self.filerefs = [decoder decodeObjectForKey:@"filerefs"];
	
	// will be zero if no timerinterval was saved
	timerinterval = [decoder decodeInt32ForKey:@"timerinterval"];
	
	// skip the calendar and filemanager fields; they're not needed

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
		
		if (win.type == wintype_Pair) {
			GlkWindowPair *pairwin = (GlkWindowPair *)win;
			pairwin.child1 = [self windowForTag:pairwin.geometry.child1tag];
			pairwin.child2 = [self windowForTag:pairwin.geometry.child2tag];
		}
	}
	
	for (GlkStream *str in streams) {
		switch (str.type) {
			case strtype_Window: {
				GlkStreamWindow *winstr = (GlkStreamWindow *)str;
				if (winstr.wintag)
					winstr.win = [self windowForTag:winstr.wintag];
			}
			break;
			default:
				break;
		}
	}
	
	// We don't worry about glkdelegate or the dispatch hooks. (Because this will only be used through updateFromLibrary). Similarly, none of the windows need stylesets yet, and none of the file streams are really open.
	
	return self;
}

- (void) dealloc {
	//NSLog(@"GlkLibrary dealloc %x", (unsigned int)self);
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
	NSLog(@"### GlkLibrary: encoding with %d windows, %d streams, %d filerefs", windows.count, streams.count, filerefs.count);
	[encoder encodeInt:SERIAL_VERSION forKey:@"version"];
	
	NSAssert(!vmexited && specialrequest == nil, @"GlkLibrary tried to serialize in special input state");
	
	[encoder encodeCGRect:bounds forKey:@"bounds"];
	
	[encoder encodeObject:windows forKey:@"windows"];
	[encoder encodeObject:streams forKey:@"streams"];
	[encoder encodeObject:filerefs forKey:@"filerefs"];

	if (timerinterval)
		[encoder encodeInt32:timerinterval forKey:@"timerinterval"];

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

/* Set the library state flag that indicates that glk_exit() has been called. (Or glk_main() returned normally.)
 */
- (void) setVMExited {
	self.vmexited = YES;
	
	[glkdelegate vmHasExited];
}

/* The player wants to restart the app after a glk_exit(). Clean up all the library state and prepare for a restart.
 */
- (void) clearForRestart {
	if (rootwin) {
		// This takes care of all the windows
		glk_window_close(rootwin, NULL);
	}
	while (streams.count) {
		GlkStream *str = [streams objectAtIndex:0];
		glk_stream_close(str, NULL);
	}
	while (filerefs.count) {
		GlkFileRef *fref = [filerefs objectAtIndex:0];
		glk_fileref_destroy(fref);
	}
	
	self.vmexited = NO;
	timerinterval = 0;
	glk_request_timer_events(timerinterval);
	
	NSAssert(windows.count == 0 && streams.count == 0 && filerefs.count == 0, @"clearForRestart: unclosed objects remain!");
	NSAssert(currentstr == nil && rootwin == nil, @"clearForRestart: root references remain!");
}

/* When the UI sees the screen change size, it calls this to tell the library. (On iOS, that happens only because of device rotation. Or the keyboard opening or closing. Or a phone call, probably. Okay, lots of reasons.) The UI also calls this if the window stylesets needs to change (because the player changed a preference).
 
	More precisely, the UI calls noteMetricsChanged or setFrameSize, which set flags and signal the selectEvent loop (VM thread) to wake up and call this.
 
	Returns YES if the geometry changed (in a way visible to the VM -- i.e., grid window rows/cols changed). This errs on the side of YES, however. (A one-pixel change probably won't change the window, but it will return YES anyhow.)
 
	This is called only at startup time and from the selectEvent loop.
*/
- (BOOL) setMetricsChanged:(BOOL)didmetschange bounds:(CGRect *)boxref {
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
	if (didmetschange) {
		metricschanged = YES;
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
					NSLog(@"### setMetrics: geometry charbox %f", geometry.keystyleset.charbox.height);
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

/* Locate the stream matching a given tag. (Or nil, if no stream matches or the tag is nil.) This isn't efficient, but it's not heavily used.
 */
- (GlkStream *) streamForTag:(NSNumber *)tag {
	if (!tag)
		return nil;
	
	for (GlkStream *str in streams) {
		if ([str.tag isEqualToNumber:tag])
			return str;
	}
	
	return nil;
}

/* Mark all the window data as "changed", so that the next update clones everything. (We call this when the window views need to discard all of their knowledge of the displayed state.
 */
- (void) dirtyAllData {
	everythingchanged = YES;
	metricschanged = YES;
	geometrychanged = YES;
	for (GlkWindow *win in windows) {
		[win dirtyAllData];
	}
}

/* Clone the library display state for a UI update. (This doesn't produce a GlkLibrary object; rather, it builds a subset which contains only what the UI cares about.)
 
	Despite the name "clone", this returns an autoreleased object, not a retained one.
 
	This runs in the VM thread; the cloned GlkLibraryState is then thrown across to the UI thread, which owns it thereafter.
 */
- (GlkLibraryState *) cloneState {
	GlkLibraryState *state = [[[GlkLibraryState alloc] init] autorelease];
	[self sanityCheck];
	
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
	state.metricschanged = metricschanged;
	metricschanged = NO;
	state.everythingchanged = everythingchanged;
	everythingchanged = NO;
	
	return state;
}

/* Import one library's state into this one, replacing the current state.
 
	This is used only during an autorestore (out-of-band restore), where the entire library state (as well as the game state) is being deserialized. One might imagine that it would be easier to just say "IosGlkAppDelegate.library = otherlib", and maybe it is, but I don't want to worry about setup issues (like getting all the dispatch hooks set right). This is more self-contained, and it's not like we don't have to iterate through things and do extra setup anyhow.
 
	This destroys otherlib in the process of reading it. Don't try to use otherlib for anything afterwards.
 */
- (void) updateFromLibrary:(GlkLibrary *)otherlib {
	/* First close all the windows and streams and filerefs. (It only really matters for streams, which need to be flushed, but it's cleaner to close everything.) */
	[self clearForRestart];
	vmexited = otherlib.vmexited;
	
	self.rootwin = otherlib.rootwin;
	self.currentstr = otherlib.currentstr;
	self.specialrequest = otherlib.specialrequest;
	self.timerinterval = otherlib.timerinterval;
	
	tagCounter = otherlib.tagCounter;
	
	for (GlkWindow *win in otherlib.windows) {
		win.library = self;
		[windows addObject:win];
	}
	for (GlkStream *str in otherlib.streams) {
		str.library = self;
		[streams addObject:str];
	}
	for (GlkFileRef *fref in otherlib.filerefs) {
		fref.library = self;
		[filerefs addObject:fref];
	}
	
	//### dispatch registry? array registry?

	for (GlkWindow *win in windows) {
		if (win.type == wintype_TextGrid || win.type == wintype_TextBuffer) {
			win.styleset = [StyleSet buildForWindowType:win.type rock:win.rock];
		}
	}
	for (GlkWindow *win in windows) {
		if (win.type == wintype_Pair) {
			GlkWindowPair *pairwin = (GlkWindowPair *)win;
			GlkWindow *keywin = [self windowForTag:pairwin.geometry.keytag];
			if (keywin) {
				pairwin.geometry.keystyleset = keywin.styleset;
			}
		}
	}
	
	NSMutableArray *failedstreams = [NSMutableArray arrayWithCapacity:4];
	for (GlkStream *str in streams) {
		if (str.type == strtype_File) {
			GlkStreamFile *filestr = (GlkStreamFile *)str;
			BOOL res = [filestr reopenInternal];
			if (!res)
				[failedstreams addObject:str];
		}
		else if (str.type == strtype_Memory) {
			//### memory streams, set up pointers. (These require delving into the interpreter.)
		}
	}
	
	for (GlkStream *str in failedstreams) {
		NSLog(@"### stream %@ failed to reopen; closing it", str);
		glk_stream_close(str, nil);
	}
		
	/* Ensure that the UI thread has begun or stopped the timer callback, as appropriate. */ 
	glk_request_timer_events(timerinterval);

	// We should now have a complete, consistent GlkLibrary state.
	[self sanityCheck];
	[self dirtyAllData];

	// Let's be really clear about destroying otherlib.
	otherlib.rootwin = nil;
	otherlib.currentstr = nil;
	otherlib.windows = nil;
	otherlib.streams = nil;
	otherlib.filerefs = nil;
	otherlib.specialrequest = nil;
}

- (void) sanityCheck {
	#ifdef DEBUG
	
	if (rootwin && !windows.count)
		NSLog(@"SANITY: root window but no listed windows");
	if (!rootwin && windows.count)
		NSLog(@"SANITY: no root window but listed windows");
	if (rootwin && [windows indexOfObject:rootwin] == NSNotFound)
		NSLog(@"SANITY: root window not listed");
	
	if (currentstr && [streams indexOfObject:currentstr] == NSNotFound)
		NSLog(@"SANITY: current stream not listed");

	for (GlkWindow *win in windows) {
		if (!win.type)
			NSLog(@"SANITY: window lacks type");
			
		if (!win.parent) {
			if (win != rootwin)
				NSLog(@"SANITY: window has no parent but is not rootwin");
		}
		else {
			if (!NumberMatch(win.parenttag, win.parent.tag))
				NSLog(@"SANITY: window parent tag mismatch");
			if (win.parent.type != wintype_Pair)
				NSLog(@"SANITY: window parent is not pair");
		}
		if (!win.stream)
			NSLog(@"SANITY: window lacks stream");
		if (!NumberMatch(win.stream.tag, win.streamtag))
			NSLog(@"SANITY: window stream tag mismatch");
		if (win.stream.type != strtype_Window)
			NSLog(@"SANITY: window stream is wrong type");
		if (!NumberMatch(win.echostream.tag, win.echostreamtag))
			NSLog(@"SANITY: window echo stream tag mismatch");
		
		if (win.type != wintype_Pair && !win.styleset) 
			NSLog(@"SANITY: non-pair window lacks styleset");
		
		switch (win.type) {
			case wintype_Pair: {
				GlkWindowPair *pairwin = (GlkWindowPair *)win;
				if (!pairwin.child1)
					NSLog(@"SANITY: pair win has no child1");
				if (!pairwin.child2)
					NSLog(@"SANITY: pair win has no child2");
				if (!pairwin.geometry)
					NSLog(@"SANITY: pair win has no geometry");
				if (!NumberMatch(pairwin.child1.tag, pairwin.geometry.child1tag))
					NSLog(@"SANITY: pair child1 tag mismatch");
				if (!NumberMatch(pairwin.child2.tag, pairwin.geometry.child2tag))
					NSLog(@"SANITY: pair child2 tag mismatch");
				if (pairwin.styleset)
					NSLog(@"SANITY: pair window has styleset");
				if (pairwin.keydamage)
					NSLog(@"SANITY: pair window has leftover keydamage");
			}
			break;
				
			case wintype_TextBuffer: {
				GlkWindowBuffer *bufwin = (GlkWindowBuffer *)win;
				if (!bufwin.lines)
					NSLog(@"SANITY: buffer window has no lines");
			}
			break;
				
			case wintype_TextGrid: {
				GlkWindowGrid *gridwin = (GlkWindowGrid *)win;
				if (!gridwin.lines)
					NSLog(@"SANITY: grid window has no lines");
			}
			break;
		}
	}
	
	for (GlkStream *str in streams) {
		if (!str.type)
			NSLog(@"SANITY: stream lacks type");
		if (!(str.readable || str.writable))
			NSLog(@"SANITY: stream should be readable or writable");
		
		switch (str.type) {
			case strtype_Window: {
				GlkStreamWindow *winstr = (GlkStreamWindow *)str;
				if (!NumberMatch(winstr.win.tag, winstr.wintag))
					NSLog(@"SANITY: window stream tag mismatch");
				if (winstr.win.stream != winstr)
					NSLog(@"SANITY: window stream does not match stream of window");
			}
			break;
				
			case strtype_File: {
				GlkStreamFile *filestr = (GlkStreamFile *)str;
				if (!filestr.pathname)
					NSLog(@"SANITY: file stream lacks pathname");
				if (!filestr.handle)
					NSLog(@"SANITY: file stream lacks file handle");
			}
			break;
				
			case strtype_Memory: {
				GlkStreamMemory *memstr = (GlkStreamMemory *)str;
				// Remember, the buffer may be nil as long as the length limit is zero
				if (memstr.unicode && memstr.buf)
					NSLog(@"SANITY: memory stream is unicode, but has buf");
				if (!memstr.unicode && memstr.ubuf)
					NSLog(@"SANITY: memory stream is not unicode, but has ubuf");
				if (!memstr.buf && !memstr.ubuf && memstr.buflen)
					NSLog(@"SANITY: memory stream has no buffer, but positive buflen");
			}
			break;
				
			default:
				break;
		}
	}
	
	for (GlkFileRef *fref in filerefs) {
		if (!fref.pathname)
			NSLog(@"SANITY: fileref has no pathname");
	}
	
	#endif // DEBUG
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



@implementation GlkExitException
@end

