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
			[htmltext addObject:[spanArray objectAtIndex:stystr.style]];
			[htmltext addObject:str];
			[htmltext addObject:@"</span>"];
		}
	}
	
	[bufwin.updatetext removeAllObjects];
	[htmltext addObject:@"</html>\n"];
	
	NSString *htmlstr = [htmltext componentsJoinedByString:@""];
	//NSLog(@"The HTML string: %@", htmlstr);
	[webview loadHTMLString:htmlstr baseURL:cssurl];
}


@end
