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
		
	event_t dummy;
	if (!event)
		event = &dummy;
	[appwrap selectEvent:event special:nil]; 
}

void glk_select_poll(event_t *event) {
	GlkAppWrapper *appwrap = [GlkAppWrapper singleton];
	if (!appwrap)
		[NSException raise:@"GlkException" format:@"glk_select_poll: no AppWrapper"];
		
	event_t dummy;
	if (!event)
		event = &dummy;
	[appwrap selectPollEvent:event]; 
}

void glk_request_timer_events(glui32 millisecs) {
	GlkLibrary *library = [GlkLibrary singleton];
	library.timerinterval = millisecs;
	
	GlkAppWrapper *appwrap = [GlkAppWrapper singleton];
	NSNumber *interval = nil;
	if (millisecs) {
		interval = @((double)millisecs * 0.001);
	}
	[appwrap performSelectorOnMainThread:@selector(setTimerInterval:) withObject:interval waitUntilDone:NO];
}

