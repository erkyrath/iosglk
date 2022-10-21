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
	event_t *iowait_evptr; /* the place to stuff the event data when it arrives. */
	id iowait_special; /* ditto, for special event requests. (A container type, currently GlkFileRefPrompt.) */
	NSThread *thread; /* not locked; does not change through the run cycle. */
	BOOL pendingupdaterequest; /* the frameview (UI thread) wants an update on library state */
	BOOL pendingupdatefromtop; /* the frameview has lost its memory, and needs an update "from the top" (all data, dirty or not) */
	CGRect pendingsize;
}

@property (NS_NONATOMIC_IOSONLY, strong) NSCondition *iowaitcond; /* must hold this lock to touch any of the fields below, unless otherwise noted. */
@property (NS_NONATOMIC_IOSONLY) BOOL iowait; /* true when waiting for an event; becomes false when one arrives. */
@property (NS_NONATOMIC_IOSONLY, strong) GlkEventState *eventfromui; /* a prospective event coming in from the UI. */
@property (NS_NONATOMIC_IOSONLY, strong) NSNumber *timerinterval;

@property (NS_NONATOMIC_IOSONLY) BOOL pendingtimerevent;
@property (NS_NONATOMIC_IOSONLY) BOOL pendingmetricchange; /* the fonts or font sizes have just changed */
@property (NS_NONATOMIC_IOSONLY) BOOL pendingsizechange; /* the frame rectangle has just changed (to pendingsize) */
@property (NS_NONATOMIC_IOSONLY) NSTimeInterval lastwaittime; /* not locked; only touched by VM thread internals. */
@property (NS_NONATOMIC_IOSONLY) glui32 lasteventtype; /* not locked; only touched by the VM thread. */

+ (GlkAppWrapper *) singleton;

- (void) launchAppThread;
- (void) requestViewUpdate;
- (void) setFrameSize:(CGRect)box;
- (void) noteMetricsChanged;
- (void) selectEvent:(event_t *)event special:(id)special;
- (void) selectPollEvent:(event_t *)event;
- (void) acceptEvent:(GlkEventState *)event;
- (void) acceptEventFileSelect:(GlkFileRefPrompt *)prompt;
- (void) acceptEventRestart;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL acceptingEvent;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL acceptingEventFileSelect;
- (NSString *) editingTextForWindow:(NSNumber *)tag;
- (void) setTimerInterval:(NSNumber *)interval;
- (void) fireTimer:(id)dummy;

@end


@interface GlkEventState : NSObject {
	glui32 type;
	glui32 ch;
	glui32 genval1;
	glui32 genval2;
	NSString *line;
	NSNumber *tag;
}

@property (nonatomic) glui32 type;
@property (nonatomic) glui32 ch;
@property (nonatomic) glui32 genval1;
@property (nonatomic) glui32 genval2;
@property (nonatomic, strong) NSString *line;
@property (nonatomic, strong) NSNumber *tag;

+ (GlkEventState *) charEvent:(glui32)ch inWindow:(NSNumber *)tag;
+ (GlkEventState *) lineEvent:(NSString *)line inWindow:(NSNumber *)tag;
+ (GlkEventState *) timerEvent;

@end

