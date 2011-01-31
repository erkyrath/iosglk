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
	GlkWinBufferView *win = [[[GlkWinBufferView alloc] initWithFrame:self.bounds] autorelease];
	win.dispid = 111;
	[self addSubview:win];
	[windows setObject:win forKey:[NSNumber numberWithUnsignedInt:win.dispid]];
}

- (void) dealloc {
	self.windows = nil;
	[super dealloc];
}

- (void) layoutSubviews {
	NSLog(@"frameview layoutSubviews");
	
	GlkWinBufferView *winv = [windows objectForKey:[NSNumber numberWithUnsignedInt:111]];
	if (winv) {
		winv.frame = self.bounds;
	}
}

- (void) updateFromLibraryState:(GlkLibrary *)library {
	NSLog(@"updateFromLibraryState");
	
	if (!library)
		[NSException raise:@"GlkException" format:@"updateFromLibraryState: no library"];
	
	//### the following should be window-specific

	NSMutableArray *htmltext = [NSMutableArray arrayWithCapacity:16];
	[htmltext addObject:@"<html>\n"];
	[htmltext addObject:@"<link rel=\"stylesheet\" href=\"general.css\" type=\"text/css\">\n"];
	
	GlkWindowBuffer *win = (GlkWindowBuffer *)library.rootwin;
	NSMutableArray *updates = win.updatetext;
	
	for (GlkStyledLine *sln in updates) {
		if (sln.status)
			[htmltext addObject:@"\n"];
		for (GlkStyledString *stystr in sln.arr) {
			NSMutableString *str = [NSMutableString stringWithString:stystr.str];
			NSRange range;
			range.location = 0;
			range.length = str.length;
			[str replaceOccurrencesOfString:@"&" withString:@"&amp;" options:NSLiteralSearch range:range];
			range.length = str.length;
			[str replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSLiteralSearch range:range];
			range.length = str.length;
			[str replaceOccurrencesOfString:@">" withString:@"&gt;" options:NSLiteralSearch range:range];
			[htmltext addObject:str];
		}
	}
	
	[win.updatetext removeAllObjects];
	[htmltext addObject:@"</html>\n"];
	
	GlkWinBufferView *winv = [windows objectForKey:[NSNumber numberWithUnsignedInt:111]];
	if (winv) {
		NSString *htmlstr = [htmltext componentsJoinedByString:@""];
		NSLog(@"The HTML string: %@", htmlstr);
		[winv.webview loadHTMLString:htmlstr baseURL:winv.cssurl];
	}
}

@end
