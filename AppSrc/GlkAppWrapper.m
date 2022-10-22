/* GlkAppWrapper.m: Class which manages the program (VM) thread
    for IosGlk, the iOS implementation of the Glk API.
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://eblong.com/zarf/glk/
*/

/*  This class contains the VM thread, and the methods that synchronize it with the main (UI) thread.

    The portable Glk program runs in its own thread (which I'll refer to as "the VM thread", even if the program isn't a virtual machine per se). It has a simple lifecycle: it runs along for a while, and then it calls glk_select(). That blocks and waits for the UI thread to send some kind of input event. (Presumably a response to the input requests that the Glk program has made.) When an event arrives, the VM thread wakes up and processes it.

    The iowait flag indicates whether the VM thread is awake or asleep. It is set when the VM enters glk_select(); it is cleared when an input event arrives.

    Coordinating threads is always a headache, of course. We do all our synchronization using iowaitcond, an NSCondition variable. (NSConditions are also thread locks.) Any cross-thread variable -- principly iowait, but there are a handful of others -- may only be accessed while holding iowaitcond.

    Note, however, that the VM thread does not hold iowaitcond the whole time it is running. It leaves that free in normal operation. (The main thread sometimes grabs it to pass in information, such as window size changes that happen while the VM thread is awake.) The VM thread only takes iowaitcond when it is setting up a glk_select().
*/

#import "GlkAppWrapper.h"
#import "GlkLibrary.h"
#import "GlkWindow.h"
#import "IosGlkViewController.h"
#import "GlkFrameView.h"
#import "GlkFileTypes.h"
#import "GlkUtilTypes.h"
#import "GlkUtilities.h"
#include "glk.h"
#include "iosglk_startup.h"

@implementation GlkAppWrapper

static GlkAppWrapper *singleton = nil;

+ (GlkAppWrapper *) singleton {
    return singleton;
}

- (instancetype) init {
    self = [super init];

    if (self) {
        if (singleton)
            [NSException raise:@"GlkException" format:@"cannot create two GlkAppWrapper objects"];
        singleton = self;

        _iowait = NO;
        _eventfromui = nil;
        iowait_evptr = nil;
        iowait_special = nil;
        _pendingtimerevent = NO;
        self.iowaitcond = [[[NSCondition alloc] init] autorelease];

        _pendingmetricchange = NO;
        _pendingsizechange = NO;
        _timerinterval = nil;
    }

    return self;
}

- (void) dealloc {
    if (singleton == self)
        singleton = nil;
	self.timerinterval = nil;
	self.eventfromui = nil;
	[super dealloc];
}

- (void) launchAppThread {

    GlkAppWrapper __weak *weakSelf = self;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		weakSelf.looppool = [[NSAutoreleasePool alloc] init];
		//NSLog(@"VM thread starting");

        [weakSelf.iowaitcond lock];
        weakSelf.iowait = NO;
        weakSelf.eventfromui = nil;
        weakSelf.pendingmetricchange = NO;
        weakSelf.pendingsizechange = NO;
        weakSelf.pendingtimerevent = NO;
        [weakSelf.iowaitcond unlock];

        iosglk_startup_code();

        while (YES) {

            //NSLog(@"VM thread running glk_main()");
            @try {
                weakSelf.lasteventtype = -1; // meaning startup
                weakSelf.lastwaittime = [NSDate timeIntervalSinceReferenceDate];
                glk_main();
            } @catch (GlkExitException *ce) {
                NSLog(@"VM thread caught glk_exit exception");
            }

            GlkLibrary *library = [GlkLibrary singleton];
            [library setVMExited];
            /* Wait for the special restart button to be pushed. */
            library.specialrequest = [NSNull null];
            [self selectEvent:nil special:library.specialrequest];
            library.specialrequest = nil;

            [library clearForRestart];
        }

	    [weakSelf.looppool drain]; // releases it
	    weakSelf.looppool = nil;
	    //NSLog(@"VM thread exiting");
    });
}

/* ### Have a glk_tick() which drains the looppool? Timing would be tricky... Maybe measure the pool size once per thousand opcodes */

/* Block and wait for an event to arrive. This is called to wait for a regular Glk event (in which case event must be non-null), or for a special request (e.g., file selection) (in which case special must be non-null). If both arguments are null, this will block forever and ignore all UI input.

    This must be called on the VM thread.
*/
- (void) selectEvent:(event_t *)event special:(id)special {
    /* This is a good time to drain and recreate the thread's autorelease pool. We'll also do this in glk_tick(). */
	[_looppool drain]; // releases it
	_looppool = [[NSAutoreleasePool alloc] init];

    GlkLibrary *library = [GlkLibrary singleton];

    if (event && special)
        [NSException raise:@"GlkException" format:@"selectEvent called with both event and special arguments"];
    if (special != library.specialrequest)
        [NSException raise:@"GlkException" format:@"selectEvent called with wrong special value"];

    [_iowaitcond lock];
    //NSLog(@"VM thread glk_select after %lf (event %x, special %x)", [NSDate timeIntervalSinceReferenceDate]-lastwaittime, (unsigned int)event, (unsigned int)special);

    if (event) {
        event->type = 0;
        event->win = NULL;
        event->val1 = 0;
        event->val2 = 0;
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
    /* Make sure we start out the wait loop with a updateFromLibraryState call. */
    pendingupdaterequest = YES;
    pendingupdatefromtop = NO;
    _pendingtimerevent = NO;
    _iowait = YES;

    while (self.iowait) {
        if (pendingupdaterequest) {
            pendingupdaterequest = NO;
            if (pendingupdatefromtop) {
                pendingupdatefromtop = NO;
                //NSLog(@"dirtying all library data for brand-new frameview!");
                [library dirtyAllData];
            }
            /* It's possible there's no frameview right now. If not, the call will be a no-op. When the frameview comes along, it will call requestViewUpdate and we'll get back to it. */
            IosGlkViewController *glkviewc = [IosGlkViewController singleton];
            [glkviewc performSelectorOnMainThread:@selector(updateFromLibraryState:) withObject:library.cloneState waitUntilDone:NO];
        }

        if (event && (_pendingsizechange || _pendingmetricchange)) {
            /* This could be set while we're waiting, or it could have been set already when we entered selectEvent. Note that we won't get in here if this is a special event request (because event will be null). */
            BOOL metricschanged = _pendingmetricchange;
            CGRect *boxref = nil;
            if (_pendingsizechange) {
                boxref = &pendingsize;
            }
            _pendingsizechange = NO;
            _pendingmetricchange = NO;

            BOOL sizechanged = [library setMetricsChanged:metricschanged bounds:boxref];
            if (sizechanged) {
                /* We duplicate all the event-setting machinery here, because we're already in the VM thread and inside the lock. */
                iowait_evptr = NULL;
                event->type = evtype_Arrange;
                event->win = nil;
                event->val1 = 0;
                event->val2 = 0;
                _iowait = NO;
                break;
            }
        }

        /* Wait for a signal from the VM thread. */
        [_iowaitcond wait];

        GlkEventState *gotevent = nil;
        if (_eventfromui) {
            gotevent = [[_eventfromui retain] autorelease];
            self.eventfromui = nil;
        }
        if (gotevent && event) {
            /* An event has arrived! If it is acceptable, set the event fields and turn off iowait. */
            GlkWindow *win = [library windowForTag:gotevent.tag]; // will be nil if there's no tag
            glui32 ch;
            int len;
            switch (gotevent.type) {
                case evtype_CharInput:
                    ch = gotevent.ch;
                    if (win && [win acceptCharInput:&ch]) {
                        event->type = evtype_CharInput;
                        event->win = win;
                        event->val1 = ch;
                        event->val2 = 0;
                        _iowait = NO;
                    }
                    break;
                case evtype_LineInput:
                    if (win) {
                        len = [win acceptLineInput:gotevent.line];
                        /* len might be shorter than the text string, either because the buffer is short or utf16 crunching. */
                        if (len >= 0) {
                            event->type = evtype_LineInput;
                            event->win = win;
                            event->val1 = len;
                            event->val2 = 0;
                            _iowait = NO;
                        }
                    }
                    break;
                case evtype_Timer:
                    /* Acceptable if the library has requested timer events. (If the library just cancelled the timer, it should ignore a late-arriving timer event.) */
                    if (library.timerinterval) {
                        event->type = evtype_Timer;
                        event->win = 0;
                        event->val1 = 0;
                        event->val2 = 0;
                        _iowait = NO;
                    }
                    break;
                default:
                    if (gotevent.type >= 0x8000000) {
                        /* This is a custom event type. Pass it through unmolested. */
                        event->type = gotevent.type;
                        event->win = win;
                        event->val1 = gotevent.genval1;
                        event->val2 = gotevent.genval2;
                        _iowait = NO;
                    }
                    break;
            }
        }
    }

    _lasteventtype = (event ? event->type : evtype_None);
    _lastwaittime = [NSDate timeIntervalSinceReferenceDate];
    //NSLog(@"VM thread glk_select returned (evtype %d)", (event ? event->type : -1));
    [_iowaitcond unlock];
}

/* Check if one of the internal event types has arrived. (That includes timer and resize events, not input events.)
    This must be called on the VM thread.
*/
- (void) selectPollEvent:(event_t *)event {
    event->type = 0;
    event->win = NULL;
    event->val1 = 0;
    event->val2 = 0;
    [_iowaitcond lock];
    if (_pendingtimerevent) {
        _pendingtimerevent = NO;
        event->type = evtype_Timer;
    }
    [_iowaitcond unlock];
}

/* The UI wants an update (updateFromLibraryState) call.

    This is called from the main thread. It synchronizes with the VM thread.
 */
- (void) requestViewUpdate {
    [_iowaitcond lock];
    pendingupdaterequest = YES;
    pendingupdatefromtop = YES;
    [_iowaitcond signal];
    [_iowaitcond unlock];
}

/* The UI's frame size has changed. All the UI windowviews are already resized; now we have to update the VM's windows equivalently. (The VM's windows may no longer match the UI, but that's okay -- the UI will catch up.)

    This is called from the main thread. It synchronizes with the VM thread. If the VM thread is blocked, it will wake up briefly to handle the size change (and maybe begin a evtype_Arrange event). If the VM thread is running, it will get back to the size change at the next glk_select() time. */
- (void) setFrameSize:(CGRect)box {
    //NSLog(@"setFrameSize: %@", StringFromRect(box));
    [_iowaitcond lock];
    _pendingsizechange = YES;
    pendingsize = box;
    [_iowaitcond signal];
    [_iowaitcond unlock];
}

/* The UI's fonts or font sizes have changed. Again, all the UI windowviews have already done this; we need to apply the changes to the VM windows. (It matters because, for example, a GlkGridWindow might now be a different number of characters across.) This involves telling the VM windows to grab newly-computed stylesets.

    This is called from the main thread. It synchronizes with the VM thread. If the VM thread is blocked, it will wake up briefly to handle the size change (and maybe begin a evtype_Arrange event). If the VM thread is running, it will get back to the size change at the next glk_select() time. */
- (void) noteMetricsChanged {
    //NSLog(@"setFrameSize: %@", StringFromRect(box));
    [_iowaitcond lock];
    _pendingmetricchange = YES;
    [_iowaitcond signal];
    [_iowaitcond unlock];
}

/* Check whether the VM is blocked and waiting for events. (Special filename-prompt blocking doesn't count!)
    This is called from the main thread. It synchronizes with the VM thread. */
- (BOOL) acceptingEvent {
    BOOL res;
    [_iowaitcond lock];
    res = self.iowait && iowait_evptr;
    [_iowaitcond unlock];
    return res;
}

/* Check whether the VM is blocked and waiting for a special prompt event.
    This is called from the main thread. It synchronizes with the VM thread. */
- (BOOL) acceptingEventFileSelect {
    BOOL res;
    [_iowaitcond lock];
    res = self.iowait && iowait_special && [iowait_special isKindOfClass:[GlkFileRefPrompt class]];
    [_iowaitcond unlock];
    return res;
}

/* This is called from the VM thread, while the VM is running. It throws a call into the main thread, where the user is (presumably) busy editing an input field. */
- (NSString *) editingTextForWindow:(NSNumber *)tag {
    GlkFrameView *frameview = [IosGlkViewController singleton].frameview;
    if (!frameview)
        return nil;

    GlkTagString *tagstring = [[GlkTagString alloc] initWithTag:tag text:nil]; // retain

    // Block waiting for main thread to update tagstring
    [frameview performSelectorOnMainThread:@selector(editingTextForWindow:)
        withObject:tagstring waitUntilDone:YES];

	NSString *result = [[tagstring.str retain] autorelease];
	[tagstring release];
    return result;
}

/* The UI calls this to report an input event.

    This is called from the main thread. It synchronizes with the VM thread.
*/
- (void) acceptEvent:(GlkEventState *)event {
    event = [[IosGlkViewController singleton] filterEvent:event];
    if (!event)
        return;

    [_iowaitcond lock];

    if (!self.iowait || !iowait_evptr) {
        /* The VM thread is working, or else it's waiting for a file selection, or the game has ended. Events not accepted right now. However, we'll set a flag in case someone comes along and polls for it. */
        if (event.type == evtype_Timer)
            _pendingtimerevent = YES;
        //### size change event too?
        [_iowaitcond unlock];
        return;
    }

    /* We'll want to check, inside the VM thread, to make sure the event is really acceptable. So we don't turn off iowait just yet. */
    self.eventfromui = event;
    [_iowaitcond signal];
    [_iowaitcond unlock];
}

/* The UI calls this to report that file selection is complete. The chosen pathname (or nil, if cancelled) is in the prompt object (which should match the prompt that was originally passed out).

    This is called from the main thread. It synchronizes with the VM thread.
*/
- (void) acceptEventFileSelect:(GlkFileRefPrompt *)prompt {
    prompt = [[IosGlkViewController singleton] filterEvent:prompt];
    if (!prompt)
        return;

    [_iowaitcond lock];

    if (!self.iowait || !iowait_special || ![iowait_special isKindOfClass:[GlkFileRefPrompt class]] || iowait_special != prompt) {
        /* The VM thread is working, or else it's waiting for a normal event, or the game has ended. Either way, our response is not accepted right now. */
        [_iowaitcond unlock];
        return;
    }

    iowait_special = nil;
    _iowait = NO;
    [_iowaitcond signal];
    [_iowaitcond unlock];
}

/* The UI calls this to report that the user has pressed the restart button (or one of them), after glk_main() has exited.

 This is called from the main thread. It synchronizes with the VM thread.
 */
- (void) acceptEventRestart {
    [_iowaitcond lock];

    if (!self.iowait || !iowait_special || ![iowait_special isKindOfClass:[NSNull class]]) {
        /* The VM thread is working, or else it's waiting for a normal event. Either way, our response is not accepted right now. */
        [_iowaitcond unlock];
        return;
    }

    iowait_special = nil;
    _iowait = NO;
    [_iowaitcond signal];
    [_iowaitcond unlock];
}

/* This method must be run on the main thread. */
- (void) setTimerInterval:(NSNumber *)interval {
    /* It isn't really possible that the interval argument is the same object as self.timerinterval. But we should be clean about the handover anyway. */
	if (interval) {
		[[interval retain] autorelease];
	}

    if (_timerinterval) {
        [GlkAppWrapper cancelPreviousPerformRequestsWithTarget:self selector:@selector(fireTimer:) object:nil];
        self.timerinterval = nil;
    }

    if (interval) {
        self.timerinterval = interval;
        /* The delay value in this method is an NSTimeInterval, which is defined as double. */
        [self performSelector:@selector(fireTimer:) withObject:nil afterDelay:_timerinterval.doubleValue];
    }

}

/* This fires on the main thread. */
- (void) fireTimer:(id)dummy {
    //NSLog(@"Timer fires!");
    if (_timerinterval) {
        [self performSelector:@selector(fireTimer:) withObject:nil afterDelay:_timerinterval.doubleValue];
    }

    [self acceptEvent:[GlkEventState timerEvent]];
}


@end
