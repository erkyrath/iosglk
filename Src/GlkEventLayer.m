/* GlkEventLayer.m: Public API for events
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	This file contains the public Glk functions dealing with events -- glk_select() and timer events.
	
	(The "layer" files connect the C-linkable API to the ObjC implementation layer. This is therefore an ObjC file that defines C functions in terms of ObjC method calls. Like all the Glk functions, these must be called from the VM thread, not the main thread.)
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

void glk_select_poll(event_t *event) {
	GlkAppWrapper *appwrap = [GlkAppWrapper singleton];
	if (!appwrap)
		[NSException raise:@"GlkException" format:@"glk_select_poll: no AppWrapper"];
	[appwrap selectPollEvent:event]; 
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

