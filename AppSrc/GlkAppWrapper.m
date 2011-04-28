/* GlkAppWrapper.m: Class which manages the program (VM) thread
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	This class contains the VM thread, and the methods that synchronize it with the main (UI) thread.

	The portable Glk program runs in its own thread (which I'll refer to as "the VM thread", even if the program isn't a virtual machine per se). It has a simple lifecycle: it runs along for a while, and then it calls glk_select(). That blocks and waits for the UI thread to send some kind of input event. (Presumably a response to the input requests that the Glk program has made.) When an event arrives, the VM thread wakes up and processes it.
	
	The iowait flag indicates whether the VM thread is awake or asleep. It is set when the VM enters glk_select(); it is cleared when an input event arrives.
	
	Coordinating threads is always a headache, of course. We do all our synchronization using iowaitcond, an NSCondition variable. (NSConditions are also thread locks.) Any cross-thread variable -- principly iowait, but there are a handful of others -- may only be accessed while holding iowaitcond.
	
	Note, however, that the VM thread does not hold iowaitcond the whole time it is running. It leaves that free in normal operation. (The main thread sometimes grabs it to pass in information, such as window size changes that happen while the VM thread is awake.) The VM thread only takes iowaitcond when it is setting up a glk_select().
*/

#import "GlkAppWrapper.h"
#import "GlkLibrary.h"
#import "IosGlkAppDelegate.h"
#import "IosGlkViewController.h"
#import "GlkFrameView.h"
#import "GlkFileTypes.h"
#import "GlkUtilTypes.h"
#import "GlkUtilities.h"
#include "glk.h"
#include "iosglk_startup.h"

@implementation GlkAppWrapper

@synthesize iowait;
@synthesize iowaitcond;
@synthesize timerinterval;

static GlkAppWrapper *singleton = nil;

+ (GlkAppWrapper *) singleton {
	return singleton;
}

- (id) init {
	self = [super init];
	
	if (self) {
		if (singleton)
			[NSException raise:@"GlkException" format:@"cannot create two GlkAppWrapper objects"];
		singleton = self;
		
		iowait = NO;
		iowait_evptr = nil;
		iowait_special = nil;
		pendingtimerevent = NO;
		self.iowaitcond = [[[NSCondition alloc] init] autorelease];
		
		pendingsizechange = NO;
		timerinterval = nil;
	}
	
	return self;
}

- (void) dealloc {
	if (singleton == self)
		singleton = nil;
	self.timerinterval = nil;
	[super dealloc];
}

- (void) launchAppThread {
	if (thread)
		[NSException raise:@"GlkException" format:@"cannot create two app threads"];
		
	thread = [[NSThread alloc] initWithTarget:self
		selector:@selector(appThreadMain:) object:nil];
	[thread start];
}

- (void) appThreadMain:(id)rock {
	looppool = [[NSAutoreleasePool alloc] init];
	NSLog(@"VM thread starting");

	[iowaitcond lock];
	iowait = NO;
	pendingsizechange = NO;
	pendingtimerevent = NO;
	[iowaitcond unlock];
	
	iosglk_startup_code();
	
	glk_main();

	[looppool drain]; // releases it
	looppool = nil;
	NSLog(@"VM thread exiting");
}

/* ### Have a glk_tick() which drains the looppool? Timing would be tricky... Maybe measure the pool size once per thousand opcodes */

/* Block and wait for an event to arrive. This is called to wait for a regular Glk event (in which case event must be non-null), or for a special request (e.g., file selection) (in which case special must be non-null). If both arguments are null, this will block forever and ignore all UI input.

	This must be called on the VM thread. 
*/
- (void) selectEvent:(event_t *)event special:(id)special {
	/* This is a good time to drain and recreate the thread's autorelease pool. We'll also do this in glk_tick(). */
	[looppool drain]; // releases it
	looppool = [[NSAutoreleasePool alloc] init];
		
	GlkLibrary *library = [GlkLibrary singleton];
	GlkFrameView *frameview = [IosGlkAppDelegate singleton].viewController.viewAsFrameView;
	
	if (event && special) 
		[NSException raise:@"GlkException" format:@"selectEvent called with both event and special arguments"];
	if (special != library.specialrequest)
		[NSException raise:@"GlkException" format:@"selectEvent called with wrong special value"];
	
	[iowaitcond lock];
	NSLog(@"VM thread glk_select (event %x, special %x)", event, special);
	
	if (event) {
		bzero(event, sizeof(event_t));
		iowait_evptr = event;
		iowait_special = nil;
	}
	else if (special) {
		iowait_special = special;
		iowait_evptr = nil;
	}
	else {
		iowait_special = nil;
		iowait_evptr = nil;
	}
	pendingtimerevent = NO;
	iowait = YES;
	
	/* These main-thread calls may not get in gear until we've settled into our iowait loop. */
	[frameview performSelectorOnMainThread:@selector(updateFromLibraryState:)
		withObject:library waitUntilDone:NO];
	
	while (self.iowait) {
		if (event && pendingsizechange) {
			/* This could be set while we're waiting, or it could have been set already when we entered selectEvent. Note that we won't get in here if this is a special event request (because event will be null). */
			pendingsizechange = NO;
			BOOL sizechanged = [library setMetrics:pendingsize];
			if (sizechanged) {
				/* We duplicate all the event-setting machinery here, because we're already in the VM thread and inside the lock. */
				iowait_evptr = NULL;
				event->type = evtype_Arrange;
				event->win = nil;
				event->val1 = 0;
				event->val2 = 0;
				iowait = NO;
				break;
			}
		}
		
		[iowaitcond wait];
	}
	
	NSLog(@"VM thread glk_select returned (evtype %d)", (event ? event->type : -1));
	[iowaitcond unlock];
}

/* Check if one of the internal event types has arrived. (That includes timer and resize events, not input events.)
	This must be called on the VM thread. 
*/
- (void) selectPollEvent:(event_t *)event {
	bzero(event, sizeof(event_t));
	
	[iowaitcond lock];
	if (pendingtimerevent) {
		pendingtimerevent = NO;
		event->type = evtype_Timer;
	}
	[iowaitcond unlock];
}

/* The UI's frame size has changed. All the UI windowviews are already resized; now we have to update the VM's windows equivalently. (The VM's windows may no longer match the UI, but that's okay -- the UI will catch up.)

	This is called from the main thread. It synchronizes with the VM thread. If the VM thread is blocked, it will wake up briefly to handle the size change (and maybe begin a evtype_Arrange event). If the VM thread is running, it will get back to the size change at the next glk_select() time. */
- (void) setFrameSize:(CGRect)box {
	//NSLog(@"setFrameSize: %@", StringFromRect(box));
	[iowaitcond lock];
	pendingsizechange = YES;
	pendingsize = box;
	[iowaitcond signal];
	[iowaitcond unlock];
}

/* Check whether the VM is blocked and waiting for events. (Special filename-prompt blocking doesn't count!)
	This is called from the main thread. It synchronizes with the VM thread. */
- (BOOL) acceptingEvent {
	BOOL res;
	[iowaitcond lock];
	res = self.iowait && iowait_evptr;
	[iowaitcond unlock];
	return res;
}

/* Check whether the VM is blocked and waiting for a special prompt event.
	This is called from the main thread. It synchronizes with the VM thread. */
- (BOOL) acceptingEventFileSelect {
	BOOL res;
	[iowaitcond lock];
	res = self.iowait && iowait_special && [iowait_special isKindOfClass:[GlkFileRefPrompt class]];
	[iowaitcond unlock];
	return res;
}

/* This is called from the VM thread, while the VM is running. It throws a call into the main thread, where the user is (presumably) busy editing an input field. */
- (NSString *) editingTextForWindow:(NSNumber *)tag {
	GlkFrameView *frameview = [IosGlkAppDelegate singleton].viewController.viewAsFrameView;
	if (!frameview)
		return nil;
	
	GlkTagString *tagstring = [[GlkTagString alloc] initWithTag:tag text:nil]; // retain
	
	[frameview performSelectorOnMainThread:@selector(editingTextForWindow:)
		withObject:tagstring waitUntilDone:YES];
		
	NSString *result = tagstring.str; // we take over the retention
	[tagstring release];
	[result autorelease];
	return result;
}

/* The UI calls this to report an input event. 
	This is called from the main thread. It synchronizes with the VM thread. 
*/
- (void) acceptEventType:(glui32)type window:(GlkWindow *)win val1:(glui32)val1 val2:(glui32)val2 {
	[iowaitcond lock];
	
	if (!self.iowait || !iowait_evptr) {
		/* The VM thread is working, or else it's waiting for a file selection. Either way, events not accepted right now. However, we'll set a flag in case someone comes along and polls for it. */
		if (type == evtype_Timer)
			pendingtimerevent = YES;
		//### size change event too?
		[iowaitcond unlock];
		return;
	}
	
	event_t *event = iowait_evptr;
	iowait_evptr = NULL;
	event->type = type;
	event->win = win;
	event->val1 = val1;
	event->val2 = val2;
	iowait = NO;
	[iowaitcond signal];
	[iowaitcond unlock];
}

/* The UI calls this to report that file selection is complete. The chosen pathname (or nil, if cancelled) is in the prompt object that was originally passed out.

	This is called from the main thread. It synchronizes with the VM thread. 
*/
- (void) acceptEventFileSelect {
	[iowaitcond lock];
	
	if (!self.iowait || !iowait_special || ![iowait_special isKindOfClass:[GlkFileRefPrompt class]]) {
		/* The VM thread is working, or else it's waiting for a normal event. Either way, our response is not accepted right now. */
		[iowaitcond unlock];
		return;
	}
	
	iowait_special = nil;
	iowait = NO;
	[iowaitcond signal];
	[iowaitcond unlock];
}

/* This method must be run on the main thread.
	The interval argument, if non-nil, must be retained by the caller. This method will release it. (This simplifies its transfer from the VM thread, which is where this is called from.) */
- (void) setTimerInterval:(NSNumber *)interval {
	if (timerinterval) {
		[GlkAppWrapper cancelPreviousPerformRequestsWithTarget:self selector:@selector(fireTimer:) object:nil];
		self.timerinterval = nil;
	}
	
	if (interval) {
		self.timerinterval = interval;
		/* The delay value in this method is an NSTimeInterval, which is defined as double. */
		[self performSelector:@selector(fireTimer:) withObject:nil afterDelay:[timerinterval doubleValue]];
		[interval release];
	}
	
}

/* This fires on the main thread. */
- (void) fireTimer:(id)dummy {
	NSLog(@"Timer fires!");
	if (timerinterval) {
		[self performSelector:@selector(fireTimer:) withObject:nil afterDelay:[timerinterval doubleValue]];
	}
	
	[self acceptEventType:evtype_Timer window:nil val1:0 val2:0];
}


@end
