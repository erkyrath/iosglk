/* GlkAppWrapper.h: Class which manages the program (VM) thread
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <Foundation/Foundation.h>
#include "glk.h"

@interface GlkAppWrapper : NSObject {
	NSCondition *iowaitcond; /* must hold this lock to touch any of the fields below, unless otherwise noted. */
	
	BOOL iowait; /* true when waiting for an event; becomes false when one arrives. */
	event_t *iowait_evptr; /* the place to stuff the event data when it arrives. */
	id iowait_special; /* ditto, for special event requests. (A container type, currently GlkFileRefPrompt.) */
	NSThread *thread; /* not locked; does not change through the run cycle. */
	NSAutoreleasePool *looppool; /* not locked; only touched by the VM thread. */
	
	BOOL pendingtimerevent;
	BOOL pendingsizechange;
	CGRect pendingsize;
	NSNumber *timerinterval; /* not locked; only touched by the main thread. */
}

@property (nonatomic, retain) NSCondition *iowaitcond;
@property (nonatomic) BOOL iowait;
@property (nonatomic, retain) NSNumber *timerinterval;

+ (GlkAppWrapper *) singleton;

- (void) launchAppThread;
- (void) appThreadMain:(id)rock;
- (void) setFrameSize:(CGRect)box;
- (void) selectEvent:(event_t *)event special:(id)special;
- (void) selectPollEvent:(event_t *)event;
- (void) acceptEventType:(glui32)type window:(GlkWindow *)win val1:(glui32)val1 val2:(glui32)val2;
- (void) acceptEventSpecial;
- (BOOL) acceptingEvent;
- (BOOL) acceptingEventSpecial;
- (NSString *) editingTextForWindow:(NSNumber *)tag;
- (void) setTimerInterval:(NSNumber *)interval;
- (void) fireTimer:(id)dummy;

@end
