/* GlkWinBufferView.m: Glk textbuffer window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "GlkWinBufferView.h"
#import "GlkWindow.h"
#import "GlkUtilTypes.h"


@implementation GlkWinBufferView

@synthesize cssurl;
@synthesize webview;
@synthesize lines;
@synthesize lastline;

static NSArray *spanArray; // retained forever

+ (void) initialize {
	spanArray = [NSArray arrayWithObjects: 
		@"<span class=\"Style_normal\">", 
		@"<span class=\"Style_emphasized\">", 
		@"<span class=\"Style_preformatted\">", 
		@"<span class=\"Style_header\">", 
		@"<span class=\"Style_subheader\">", 
		@"<span class=\"Style_alert\">", 
		@"<span class=\"Style_note\">", 
		@"<span class=\"Style_blockquote\">", 
		@"<span class=\"Style_input\">", 
		@"<span class=\"Style_user1\">", 
		@"<span class=\"Style_user2\">", 
		nil];
	[spanArray retain];
}

- (id) initWithWindow:(GlkWindow *)winref frame:(CGRect)box {
	self = [super initWithWindow:winref frame:box];
	if (self) {
		self.lines = [NSMutableArray arrayWithCapacity:8];
		self.lastline = nil;
		NSString *csspath = [[NSBundle mainBundle] pathForResource:@"general" ofType:@"css"];
		self.cssurl = [NSURL fileURLWithPath: csspath];
		self.webview = [[[UIWebView alloc] initWithFrame:self.bounds] autorelease];
		webview.dataDetectorTypes = 0;
		[self addSubview:webview];
	}
	return self;
}

- (void) dealloc {
	self.lines = nil;
	self.lastline = nil;
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
	
	NSMutableArray *updates = bufwin.updatetext;
	if (updates.count == 0)
		return;
	
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:32];
	if (lastline) {
		[arr addObject:lastline];
		self.lastline = nil;
	}
	
	for (GlkStyledLine *sln in updates) {
		if (sln.status) {
			[arr addObject:@"\n"];
			NSString *ln = [arr componentsJoinedByString:@""];
			[lines addObject:ln];
			[arr removeAllObjects];
		}
		for (GlkStyledString *stystr in sln.arr) {
			[arr addObject:[spanArray objectAtIndex:stystr.style]];
			[arr addObject:[self htmlEscapeString:stystr.str]];
			[arr addObject:@"</span>"];
		}
	}
	
	if (arr.count) {
		NSString *ln = [arr componentsJoinedByString:@""];
		self.lastline = ln;
		[arr removeAllObjects];
	}
	
	[bufwin.updatetext removeAllObjects];

	//### We'll have to trim the lines array eventually. Although not right here.

	NSMutableArray *htmltext = [NSMutableArray arrayWithCapacity:16];
	[htmltext addObject:@"<html>\n"];
	[htmltext addObject:@"<link rel=\"stylesheet\" href=\"general.css\" type=\"text/css\">\n"];
	[htmltext addObjectsFromArray:lines];
	if (lastline)
		[htmltext addObject:lastline];
	//[htmltext addObject:@"<input type=\"text\">\n"];
	[htmltext addObject:@"</html>\n"];
	
	NSString *htmlstr = [htmltext componentsJoinedByString:@""];
	//NSLog(@"The HTML string: %@", htmlstr);
	[webview loadHTMLString:htmlstr baseURL:cssurl];
}


@end
