//
//  GlkFrameView.m
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import "GlkFrameView.h"
#import "GlkWindowView.h"
#import "GlkLibrary.h"
#import "GlkWindow.h"
#include "GlkUtilities.h"

@implementation GlkFrameView

@synthesize windowviews;

- (void) awakeFromNib {
	[super awakeFromNib];
	NSLog(@"GlkFrameView awakened, bounds %@", StringFromRect(self.bounds));
	
	self.windowviews = [NSMutableDictionary dictionaryWithCapacity:8];
}

- (void) dealloc {
	self.windowviews = nil;
	[super dealloc];
}

- (void) layoutSubviews {
	NSLog(@"frameview layoutSubviews");
}

- (void) updateFromLibraryState:(GlkLibrary *)library {
	NSLog(@"updateFromLibraryState");
	
	if (!library)
		[NSException raise:@"GlkException" format:@"updateFromLibraryState: no library"];
	
	NSMutableDictionary *closed = [NSMutableDictionary dictionaryWithDictionary:windowviews];
	for (GlkWindow *win in library.windows) {
		[closed removeObjectForKey:win.tag];
	}

	for (NSNumber *tag in closed) {
		GlkWindowView *winv = [closed objectForKey:tag];
		[winv removeFromSuperview];
		[windowviews removeObjectForKey:tag];
	}
	
	closed = nil;
	
	for (GlkWindow *win in library.windows) {
		if (win.type != wintype_Pair && ![windowviews objectForKey:win.tag]) {
			GlkWindowView *winv = [GlkWindowView viewForWindow:win];
			[windowviews setObject:winv forKey:win.tag];
			[self addSubview:winv];
		}
	}
	
	NSLog(@"frameview has %d windows:", windowviews.count);
	for (NSNumber *tag in windowviews) {
		NSLog(@"... %d: %@", [tag intValue], [windowviews objectForKey:tag]);
	}
}

@end
