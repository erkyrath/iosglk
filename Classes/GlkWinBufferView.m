//
//  GlkWinBufferView.m
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import "GlkWinBufferView.h"


@implementation GlkWinBufferView

@synthesize cssurl;
@synthesize webview;

- (id) initWithWindow:(GlkWindow *)winref frame:(CGRect)box {    
	self = [super initWithWindow:winref frame:box];
	if (self) {
		NSString *csspath = [[NSBundle mainBundle] pathForResource:@"general" ofType:@"css"];
		self.cssurl = [NSURL fileURLWithPath: csspath];
		self.webview = [[[UIWebView alloc] initWithFrame:self.bounds] autorelease];
		webview.dataDetectorTypes = 0;
		[self addSubview:webview];
	}
	return self;
}

- (void) dealloc {
	self.cssurl = nil;
	self.webview = nil;
	[super dealloc];
}

- (void) layoutSubviews {
	if (webview) {
		webview.frame = self.bounds;
	}
}

/*
{
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
*/

@end
