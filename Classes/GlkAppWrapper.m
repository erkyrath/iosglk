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
@synthesize timerinterval;

static GlkAppWrapper *singleton = nil;

+ (GlkAppWrapper *) singleton {
	return singleton;
}

- (id) init {
	self = [super init];
	
	if (self) {
		if (singleton)
			[NSException raise:@"GlkException" format:@"cannot create two GlkAppWrapper objects"];
		singleton = self;
		
		self.iowait = NO;
		self.iowaitcond = [[[NSCondition alloc] init] autorelease];
		
		timerinterval = nil;
	}
	
	return self;
}

- (void) dealloc {
	if (singleton == self)
		singleton = nil;
	self.timerinterval = nil;
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
	looppool = [[NSAutoreleasePool alloc] init];
	NSLog(@"VM thread starting");

	[iowaitcond lock];
	glk_main();
	[iowaitcond unlock];

	[looppool drain]; // releases it
	looppool = nil;
	NSLog(@"VM thread exiting");
}

- (void) selectEvent:(event_t *)event {
	NSLog(@"VM thread glk_select");
	
	/* This is a good time to drain and recreate the thread's autorelease pool. We'll also do this in glk_tick(). */
	[looppool drain]; // releases it
	looppool = [[NSAutoreleasePool alloc] init];
	
	GlkLibrary *library = [GlkLibrary singleton];
	GlkFrameView *frameview = [IosGlkAppDelegate singleton].viewController.viewAsFrameView;
	
	bzero(event, sizeof(event_t));
	self.iowait = YES;
	
	[frameview performSelectorOnMainThread:@selector(updateFromLibraryState:)
		withObject:library waitUntilDone:NO];
		
	while (self.iowait) {
		[iowaitcond wait];
	}
	
	NSLog(@"VM thread glk_select returned (evtype %d)", event->type);
}

/* This is called from the main thread. It synchronizes with the VM thread. */
- (void) acceptEventType:(glui32)type window:(GlkWindow *)win val1:(glui32)val1 val2:(glui32)val2 {
	if (!self.iowait)
		return;
		
	[iowaitcond lock];
	self.iowait = NO;
	[iowaitcond signal];
	[iowaitcond unlock];
}

/* This method must be run on the main thread.
	The interval argument, if non-nil, must be retained by the caller. This method will release it. (This simplifies its transfer from the VM thread.) */
- (void) setTimerInterval:(NSNumber *)interval {
	if (timerinterval) {
		[GlkAppWrapper cancelPreviousPerformRequestsWithTarget:self selector:@selector(fireTimer:) object:nil];
		self.timerinterval = nil;
	}
	
	if (interval) {
		self.timerinterval = interval;
		/* The delay value in this method is an NSTimeInterval, which is defined as double. */
		[self performSelector:@selector(fireTimer:) withObject:nil afterDelay:[timerinterval doubleValue]];
		[interval release];
	}
	
}

/* This fires on the main thread. */
- (void) fireTimer:(id)dummy {
	NSLog(@"Timer fires!");
	if (timerinterval) {
		[self performSelector:@selector(fireTimer:) withObject:nil afterDelay:[timerinterval doubleValue]];
	}
	
	[self acceptEventType:evtype_Timer window:nil val1:0 val2:0];
}


@end
