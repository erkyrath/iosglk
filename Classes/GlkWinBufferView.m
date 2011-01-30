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

- (id)initWithFrame:(CGRect)frame {
    
	self = [super initWithFrame:frame];
	if (self) {
		NSString *csspath = [[NSBundle mainBundle] pathForResource:@"general" ofType:@"css"];
		self.cssurl = [NSURL fileURLWithPath: csspath];
		self.webview = [[[UIWebView alloc] initWithFrame:self.bounds] autorelease];
		webview.dataDetectorTypes = 0;
		[self addSubview:webview];
	}
	return self;
}

- (void)dealloc {
	self.cssurl = nil;
	self.webview = nil;
	[super dealloc];
}


@end
