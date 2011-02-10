/* GlkUtilTypes.m: Miscellaneous objc classes
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/* Some utility classes that are small and boring and don't fit anywhere else.
*/

#import "GlkUtilTypes.h"

@implementation GlkStyledLine
/* GlkStyledLine: Represents a line of text. It's just an array of GlkStyledStrings, with an additional optional flag saying "This starts a new line" or "This starts a new page." (Consider either to be a newline at the *beginning* of the GlkStyledLine, possibly with page-breaking behavior.)
*/

@synthesize status;
@synthesize arr;

- (id) initWithStatus:(GlkStyledLineStatus) initstatus {
	self = [super init];
	
	if (self) {
		status = initstatus;
		self.arr = [NSMutableArray arrayWithCapacity:16];
	}
	
	return self;
}

- (id) init {
	return [self initWithStatus:linestat_Continue];
}

- (void) dealloc {
	self.arr = nil;
	[super dealloc];
}

@end


@implementation GlkStyledString
/* GlkStyledString: Represents a span of text in a given style.

	This has extra methods to let you append more text to it (making it mutable if necessary), and then "freeze" it back to an immutable string. This fits the usage pattern of GlkWindowBuffer.
*/

@synthesize str;
@synthesize style;

- (id) initWithText:(NSString *)initstr style:(glui32)initstyle {
	self = [super init];
	
	if (self) {
		self.str = initstr;
		style = initstyle;
		ismutable = NO;
	}
	
	return self;
}

- (void) dealloc {
	self.str = nil;
	[super dealloc];
}

- (void) appendString:(NSString *)newstr {
	if (!ismutable) {
		self.str = [NSMutableString stringWithString:str];
		ismutable = YES;
	}
	[(NSMutableString*)str appendString:newstr];
}

- (void) freeze {
	if (ismutable) {
		self.str = [NSString stringWithString:str];
		ismutable = NO;
	}
}

@end
