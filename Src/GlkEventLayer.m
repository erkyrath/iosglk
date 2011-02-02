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
	[appwrap select]; 
}

void glk_put_string(char *str) {
	[[GlkLibrary singleton].rootwin putCString:str]; //###
}

void glk_set_style(glui32 styl) {
	[GlkLibrary singleton].rootwin.style = styl; //###
}

