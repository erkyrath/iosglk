//
//  GlkLibrary.m
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import "GlkLibrary.h"
#import "GlkWindow.h"
#include "GlkUtilities.h"
#include "glk.h"

@implementation GlkLibrary

@synthesize windows;
@synthesize rootwin;
@synthesize bounds;

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
		
		tagCounter = 0;
		
		self.windows = [NSMutableArray arrayWithCapacity:8];
		self.rootwin = nil;
	}
	
	return self;
}

- (void) dealloc {
	self.windows = nil;
	self.rootwin = nil;
	[super dealloc];
}

- (NSNumber *) newTag {
	tagCounter++;
	return [NSNumber numberWithInteger:tagCounter];
}

- (void) setMetrics:(CGRect)box {
	bounds = box;
	NSLog(@"library metrics now %@", StringFromRect(bounds));
}

+ (void) strictWarning:(NSString *)msg {
	NSLog(@"strict warning: %@", msg);
}

@end

extern void GlkAppWrapperSelect(void); //### put in some header


void glk_put_string(char *str) {
}

void glk_set_style(glui32 styl) {
}

void glk_select(event_t *event) {
	GlkAppWrapperSelect();
}

