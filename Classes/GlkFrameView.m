//
//  GlkFrameView.m
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import "GlkFrameView.h"
#import "GlkWinBufferView.h" //###
#import "GlkWindow.h" //###
#import "GlkUtilTypes.h" //###
#import "GlkLibrary.h" //###

@implementation GlkFrameView

@synthesize windows;

- (void) awakeFromNib {
	[super awakeFromNib];
	NSLog(@"GlkFrameView awakened");
	
	self.windows = [NSMutableDictionary dictionaryWithCapacity:8];
	
	//### temp stuff
	GlkWinBufferView *win = [[GlkWinBufferView alloc] initWithFrame:self.bounds];
	win.id = 111;
	[self addSubview:win];
	[windows setObject:win forKey:[NSNumber numberWithUnsignedInt:win.id]];
}

- (void) dealloc {
	self.windows = nil;
	[super dealloc];
}

- (void) updateFromLibraryState:(GlkLibrary *)library {
	NSLog(@"updateFromLibraryState");
	
	if (!library)
		[NSException raise:@"GlkException" format:@"updateFromLibraryState: no library"];
		
	GlkWindowBuffer *win = (GlkWindowBuffer *)library.rootwin;
	NSMutableArray *updates = win.updatetext;
	for (GlkStyledLine *sln in updates) {
		if (sln.status)
			NSLog(@"New line!");
		for (GlkStyledString *str in sln.arr) {
			NSLog(@"...'%@' (%d)", str.str, str.style);
		}
	}
	
	[win.updatetext removeAllObjects];
		
	GlkWinBufferView *winv = [windows objectForKey:[NSNumber numberWithUnsignedInt:111]];
	if (winv) {
		[winv.webview loadHTMLString:@"<html>Hello.</html>" baseURL:winv.cssurl];
	}
}

@end
