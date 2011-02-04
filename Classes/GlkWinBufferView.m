//
//  GlkWinBufferView.m
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import "GlkWinBufferView.h"
#import "GlkWindow.h"
#import "GlkUtilTypes.h"


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

- (void) updateFromWindowState {
	GlkWindowBuffer *bufwin = (GlkWindowBuffer *)win;
	
	NSMutableArray *htmltext = [NSMutableArray arrayWithCapacity:16];
	[htmltext addObject:@"<html>\n"];
	[htmltext addObject:@"<link rel=\"stylesheet\" href=\"general.css\" type=\"text/css\">\n"];
	
	NSMutableArray *updates = bufwin.updatetext;
	
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
	
	[bufwin.updatetext removeAllObjects];
	[htmltext addObject:@"</html>\n"];
	
	NSString *htmlstr = [htmltext componentsJoinedByString:@""];
	//NSLog(@"The HTML string: %@", htmlstr);
	[webview loadHTMLString:htmlstr baseURL:cssurl];
}


@end
