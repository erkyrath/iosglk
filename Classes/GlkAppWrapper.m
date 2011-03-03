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
#include "GlkUtilities.h"
#include "glk.h"


@implementation GlkAppWrapper

@synthesize iowait;
@synthesize iowait_evptr;
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
		
		self.iowait = NO;
		iowait_evptr = NULL;
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
	self.iowait = NO;
	pendingsizechange = NO;
	[iowaitcond unlock];
	
	glk_main();

	[looppool drain]; // releases it
	looppool = nil;
	NSLog(@"VM thread exiting");
}

/* Block and wait for an event to arrive.
	This must be called on the VM thread. 
*/
- (void) selectEvent:(event_t *)event {
	/* This is a good time to drain and recreate the thread's autorelease pool. We'll also do this in glk_tick(). */
	[looppool drain]; // releases it
	looppool = [[NSAutoreleasePool alloc] init];
	
	GlkLibrary *library = [GlkLibrary singleton];
	GlkFrameView *frameview = [IosGlkAppDelegate singleton].viewController.viewAsFrameView;
	
	[iowaitcond lock];
	//NSLog(@"VM thread glk_select");
	
	bzero(event, sizeof(event_t));
	self.iowait_evptr = event;
	self.iowait = YES;
	
	/* These main-thread calls may not get in gear until we've settled into our iowait loop. */
	[frameview performSelectorOnMainThread:@selector(updateFromLibraryState:)
		withObject:library waitUntilDone:NO];
	
	if (pendingsizechange) {
		pendingsizechange = NO;
		BOOL sizechanged = [library setMetrics:pendingsize];
		if (sizechanged) {
			/* This main-thread call will invoke acceptEventType, which turns off iowait. But that can't happen until we've settled into our iowait loop, because we've got the lock. */
			[frameview performSelectorOnMainThread:@selector(updateFromLibrarySize:)
				withObject:library waitUntilDone:NO];
		}
	}
		
	while (self.iowait) {
		[iowaitcond wait];
	}
	
	NSLog(@"VM thread glk_select returned (evtype %d)", event->type);
	[iowaitcond unlock];
}

/* This is called from the main thread. It synchronizes with the VM thread. */
- (void) setFrameSize:(CGRect)box {
	[iowaitcond lock];
	
	if (!self.iowait) {
		/* The VM thread is working. We'll stuff the new size into a field, and get back to it at the next glk_select call. */
		pendingsizechange = YES;
		pendingsize = box;
		[iowaitcond unlock];
		return;
	}
	
	[iowaitcond unlock];
	
	/* The VM thread is blocked. */
	
	GlkLibrary *library = [GlkLibrary singleton];
	GlkFrameView *frameview = [IosGlkAppDelegate singleton].viewController.viewAsFrameView;
	
	BOOL sizechanged = [library setMetrics:box];
	if (sizechanged) {
		/* Remember, we're still in the main thread. This call will invoke acceptEventType. */
		[frameview updateFromLibrarySize:library];
	}
}

/* The UI calls this to report an input event. 
	This is called from the main thread. It synchronizes with the VM thread. */
- (void) acceptEventType:(glui32)type window:(GlkWindow *)win val1:(glui32)val1 val2:(glui32)val2 {
	[iowaitcond lock];
	
	if (!self.iowait) {
		/* The VM thread is working; events not accepted right now. */
		[iowaitcond unlock];
		return;
	}
	
	event_t *event = self.iowait_evptr;
	self.iowait_evptr = NULL;
	if (event) {
		event->type = type;
		event->win = win;
		event->val1 = val1;
		event->val2 = val2;
	}
	self.iowait = NO;
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
