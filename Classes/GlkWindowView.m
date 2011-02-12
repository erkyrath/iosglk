/* GlkWindowView.m: Base class for a Glk window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
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

- (void) updateFromWindowState {
	[NSException raise:@"GlkException" format:@"updateFromWindowState not implemented"];
}

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
