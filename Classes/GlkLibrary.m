//
//  GlkLibrary.m
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import "GlkLibrary.h"
#import "GlkWindow.h"
#include "glk.h"

@implementation GlkLibrary

@synthesize windows;
@synthesize rootwin;

static GlkLibrary *singleton = nil; /* retained forever */

+ (GlkLibrary *) singleton {
	return singleton;
}

- (id) init {
	self = [super init];
	
	if (self) {
		if (singleton)
			[NSException raise:@"GlkException" format:@"cannot create two GlkLibrary objects"];
		singleton = [self retain];
		self.windows = [NSMutableArray arrayWithCapacity:8];
		
		self.rootwin = [GlkWindowBase windowWithType:wintype_TextBuffer rock:1]; //###tmp
	}
	
	return self;
}

- (void) dealloc {
	self.windows = nil;
	self.rootwin = nil;
	[super dealloc];
}


@end

extern void GlkAppWrapperSelect(void); //### put in some header


void glk_put_string(char *str) {
	GlkWindowBase *win = [GlkLibrary singleton].rootwin;
	[win put_string:str];
}

void glk_set_style(glui32 styl) {
	GlkWindowBase *win = [GlkLibrary singleton].rootwin;
	win->curstyle = styl;
}

void glk_select(event_t *event) {
	GlkAppWrapperSelect();
}

