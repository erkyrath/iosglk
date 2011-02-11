/* GlkWinGridView.m: Glk textgrid window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "GlkWinGridView.h"
#import "GlkWindow.h"
#import "GlkUtilTypes.h"


@implementation GlkWinGridView

@synthesize cssurl;
@synthesize webview;

- (id) initWithWindow:(GlkWindow *)winref frame:(CGRect)box {
	self = [super initWithWindow:winref frame:box];
	if (self) {
		NSString *csspath = [[NSBundle mainBundle] pathForResource:@"general" ofType:@"css"];
		self.cssurl = [NSURL fileURLWithPath: csspath];
		self.webview = [[[UIWebView alloc] initWithFrame:self.bounds] autorelease];
		webview.dataDetectorTypes = 0;
		//### make unscrollable?
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
	//GlkWindowGrid *gridwin = (GlkWindowGrid *)win;
}

@end

