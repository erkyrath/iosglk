/* GlkWindowView.m: Base class for a Glk window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	From the library's point of view, a Glk window (GlkWindow object) is a data object. It is represented on-screen by a view object, which is a subclass of GlkWindowView. These windowviews are children of the GlkFrameView.

	(We don't try to follow the Cocoa model of data changes triggering view changes. GlkWindows are totally inert. The GlkFrameView will tip us off when it's time for the windowview to update.)
*/

#import "GlkWindowView.h"
#import "GlkWinBufferView.h"
#import "GlkWinGridView.h"
#import "GlkWindow.h"

@implementation GlkWindowView

@synthesize win;

+ (GlkWindowView *) viewForWindow:(GlkWindow *)win {
	switch (win.type) {
		case wintype_TextBuffer:
			return [[[GlkWinBufferView alloc] initWithWindow:win frame:win.bbox] autorelease];
		case wintype_TextGrid:
			return [[[GlkWinGridView alloc] initWithWindow:win frame:win.bbox] autorelease];
		default:
			[NSException raise:@"GlkException" format:@"no windowview class for this window"];
			return nil; // not really
	}
}


- (id) initWithWindow:(GlkWindow *)winref frame:(CGRect)box {
	self = [super initWithFrame:box];
	if (self) {
		self.win = winref;
	}
	return self;
}

- (void) dealloc {
	self.win = nil;
	[super dealloc];
}

/* The windowview subclasses will override this. */
- (void) updateFromWindowState {
	[NSException raise:@"GlkException" format:@"updateFromWindowState not implemented"];
}

/* A utility method -- escape a string for insertion into an HTML document. */
- (NSString *) htmlEscapeString:(NSString *)val {
	NSMutableString *str = [NSMutableString stringWithString:val];
	NSRange range;
	range.location = 0;
	range.length = str.length;
	[str replaceOccurrencesOfString:@"&" withString:@"&amp;" options:NSLiteralSearch range:range];
	range.length = str.length;
	[str replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSLiteralSearch range:range];
	range.length = str.length;
	[str replaceOccurrencesOfString:@">" withString:@"&gt;" options:NSLiteralSearch range:range];
	return str;
}

@end
