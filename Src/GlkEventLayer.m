//
//  GlkEventLayer.m
//  IosGlk
//
//  Created by Andrew Plotkin on 2/2/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

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

void glk_put_string(char *str) {
	GlkWindow *win = nil;
	for (GlkWindow *wx in [GlkLibrary singleton].windows) 
		if (wx.type == wintype_TextBuffer)
			win = wx;
	[win putCString:str]; //###
}

void glk_set_style(glui32 styl) {
	GlkWindow *win = nil;
	for (GlkWindow *wx in [GlkLibrary singleton].windows) 
		if (wx.type == wintype_TextBuffer)
			win = wx;
	win.style = styl; //###
}

