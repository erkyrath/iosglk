/* GlkAppWrapper.h: Class which manages the program (VM) thread
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <Foundation/Foundation.h>
#include "glk.h"

@class GlkEventState;
@class GlkFileRefPrompt;

@interface GlkAppWrapper : NSObject {
	NSCondition *iowaitcond; /* must hold this lock to touch any of the fields below, unless otherwise noted. */
	
	BOOL iowait; /* true when waiting for an event; becomes false when one arrives. */
	GlkEventState *eventfromui; /* a prospective event coming in from the UI. */
	event_t *iowait_evptr; /* the place to stuff the event data when it arrives. */
	id iowait_special; /* ditto, for special event requests. (A container type, currently GlkFileRefPrompt.) */
	NSThread *thread; /* not locked; does not change through the run cycle. */
	NSAutoreleasePool *looppool; /* not locked; only touched by the VM thread. */
	NSTimeInterval lastwaittime; /* not locked; only touched by VM thread internals. */
	
	BOOL pendingupdaterequest; /* the frameview (UI thread) wants an update on library state */
	BOOL pendingupdatefromtop; /* the frameview has lost its memory, and needs an update "from the top" (all data, dirty or not) */
	BOOL pendingtimerevent;
	BOOL pendingmetricchange; /* the fonts or font sizes have just changed */
	BOOL pendingsizechange; /* the frame rectangle has just changed (to pendingsize) */
	CGRect pendingsize;
	NSNumber *timerinterval; /* not locked; only touched by the main thread. */
}

@property (nonatomic, retain) NSCondition *iowaitcond;
@property (nonatomic) BOOL iowait;
@property (nonatomic, retain) GlkEventState *eventfromui;
@property (nonatomic, retain) NSNumber *timerinterval;

+ (GlkAppWrapper *) singleton;

- (void) launchAppThread;
- (void) appThreadMain:(id)rock;
- (void) requestViewUpdate;
- (void) setFrameSize:(CGRect)box;
- (void) noteMetricsChanged;
- (void) selectEvent:(event_t *)event special:(id)special;
- (void) selectPollEvent:(event_t *)event;
- (void) acceptEvent:(GlkEventState *)event;
- (void) acceptEventFileSelect:(GlkFileRefPrompt *)prompt;
- (void) acceptEventRestart;
- (BOOL) acceptingEvent;
- (BOOL) acceptingEventFileSelect;
- (NSString *) editingTextForWindow:(NSNumber *)tag;
- (void) setTimerInterval:(NSNumber *)interval;
- (void) fireTimer:(id)dummy;

@end


@interface GlkEventState : NSObject {
	glui32 type;
	glui32 ch;
	NSString *line;
	NSNumber *tag;
}

@property (nonatomic) glui32 type;
@property (nonatomic) glui32 ch;
@property (nonatomic, retain) NSString *line;
@property (nonatomic, retain) NSNumber *tag;

+ (GlkEventState *) charEvent:(glui32)ch inWindow:(NSNumber *)tag;
+ (GlkEventState *) lineEvent:(NSString *)line inWindow:(NSNumber *)tag;
+ (GlkEventState *) timerEvent;

@end

