/* GlkEventLayer.m: Public API for events
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "GlkLibrary.h"
#import "GlkWindow.h"
#import "GlkAppWrapper.h"
#include "glk.h"


void glk_select(event_t *event) {
	GlkAppWrapper *appwrap = [GlkAppWrapper singleton];
	if (!appwrap)
		[NSException raise:@"GlkException" format:@"glk_select: no AppWrapper"];
	[appwrap selectEvent:event]; 
}

void glk_request_timer_events(glui32 millisecs) {
	GlkAppWrapper *appwrap = [GlkAppWrapper singleton];
	NSNumber *interval = nil;
	if (millisecs) {
		interval = [[NSNumber alloc] initWithDouble:((double)millisecs * 0.001)];
		/* This is retained, not on autorelease. We'll pass the retain over to the main thread. */
	}
	[appwrap performSelectorOnMainThread:@selector(setTimerInterval:) withObject:interval waitUntilDone:NO];
}

