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
@synthesize lines;

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
	self.lines = nil;
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
	GlkWindowGrid *gridwin = (GlkWindowGrid *)win;
	BOOL anychanges = NO;
	
	int height = gridwin.height;
	for (int jx=0; jx<gridwin.lines.count; jx++) {
		GlkGridLine *ln = [gridwin.lines objectAtIndex:jx];
		BOOL wasdirty = ln.dirty;
		ln.dirty = NO;
		if (jx < lines.count && !wasdirty)
			continue;
		
		NSMutableArray *arr = [NSMutableArray arrayWithCapacity:8];
		glui32 cursty;
		int ix = 0;
		while (ix < ln.width) {
			int pos = ix;
			cursty = ln.styles[pos];
			while (ix < ln.width && ln.styles[ix] == cursty)
				ix++;
			NSString *str = [[NSString alloc] initWithBytes:&ln.chars[pos] length:(ix-pos)*sizeof(glui32) encoding:NSUTF32LittleEndianStringEncoding];
			[arr addObject:[spanArray objectAtIndex:cursty]];
			[arr addObject:[self htmlEscapeString:str]];
			[arr addObject:@"</span>"];
		}
		[arr addObject:@"\n"];
		NSString *htmlln = [arr componentsJoinedByString:@""];
		
		//NSLog(@"gridWindow: built line %d: %@", jx, htmlln);
		if (jx < lines.count)
			[lines replaceObjectAtIndex:jx withObject:htmlln];
		else
			[lines addObject:htmlln];
		anychanges = YES;
	}
	
	while (lines.count > height) {
		[lines removeLastObject];
		anychanges = YES;
	}
	
	if (!anychanges)
		return;
	
	NSMutableArray *htmltext = [NSMutableArray arrayWithCapacity:16];
	[htmltext addObject:@"<html>\n"];
	[htmltext addObject:@"<link rel=\"stylesheet\" href=\"general.css\" type=\"text/css\">\n"];
	[htmltext addObjectsFromArray:lines];
	[htmltext addObject:@"</html>\n"];
	
	NSString *htmlstr = [htmltext componentsJoinedByString:@""];
	//NSLog(@"The HTML string: %@", htmlstr);
	[webview loadHTMLString:htmlstr baseURL:cssurl];
}

@end

