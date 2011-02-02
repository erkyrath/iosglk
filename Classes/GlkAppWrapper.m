//
//  GlkAppWrapper.m
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import "GlkAppWrapper.h"
#import "GlkLibrary.h"
#import "IosGlkAppDelegate.h"
#import "IosGlkViewController.h"
#import "GlkFrameView.h"
#include "glk.h"


@implementation GlkAppWrapper

@synthesize iowait;
@synthesize iowaitcond;

static GlkAppWrapper *singleton = nil; /* retained forever */

+ (GlkAppWrapper *) singleton {
	return singleton;
}

- (id) init {
	self = [super init];
	
	if (self) {
		if (singleton)
			[NSException raise:@"GlkException" format:@"cannot create two GlkAppWrapper objects"];
		singleton = [self retain];
		
		self.iowait = NO;
		self.iowaitcond = [[[NSCondition alloc] init] autorelease];
	}
	
	return self;
}

- (void) dealloc {
	[super dealloc];
}

- (void) launchAppThread {
	if (thread)
		[NSException raise:@"GlkException" format:@"cannot create two app threads"];
		
	thread = [[NSThread alloc] initWithTarget:self
		selector:@selector(appThreadMain:) object:nil];
	[thread start];
}

- (void) appThreadMain:(id)rock {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSLog(@"VM thread starting");

	[iowaitcond lock];
	glk_main();
	[iowaitcond unlock];

	[pool release];
	NSLog(@"VM thread exiting");
}

- (void) select {
	NSLog(@"VM thread glk_select");
	self.iowait = YES;
	
	GlkLibrary *library = [GlkLibrary singleton];
	//### go through and do final captures in buffer windows, etc.
	
	IosGlkViewController *viewc = [IosGlkAppDelegate singleton].viewController;
	GlkFrameView *frameview = viewc.viewAsFrameView;
	[frameview performSelectorOnMainThread:@selector(updateFromLibraryState:)
		withObject:library waitUntilDone:NO];
		
	while (self.iowait) {
		[iowaitcond wait];
	}
	
	NSLog(@"VM thread glk_select returned");
}

@end
