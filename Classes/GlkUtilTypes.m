/* GlkUtilTypes.m: Miscellaneous objc classes
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	Some utility classes that are small and boring and don't fit anywhere else.
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
	
	The pos field is not directly used by this class (or the GlkStyledLine class). The user may stash position information there.
*/

@synthesize str;
@synthesize style;
@synthesize pos;

- (id) initWithText:(NSString *)initstr style:(glui32)initstyle {
	self = [super init];
	
	if (self) {
		self.str = initstr;
		style = initstyle;
		ismutable = NO;
		pos = 0;
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


@implementation GlkVisualLine

@synthesize arr;
@synthesize ypos;
@synthesize height;
@synthesize linenum;

- (id) init {
	self = [super init];
	
	if (self) {
		linenum = 0;
		self.arr = [NSMutableArray arrayWithCapacity:4];
	}
	
	return self;
}

- (void) dealloc {
	self.arr = nil;
	[super dealloc];
}


@end

@implementation GlkVisualString

@synthesize str;
@synthesize style;

- (id) initWithText:(NSString *)initstr style:(glui32)initstyle {
	self = [super init];
	
	if (self) {
		self.str = initstr;
		style = initstyle;
	}
	
	return self;
}

@end

@implementation GlkGridLine
/* GlkGridLine: Represents one line of a text grid. This contains nasty C arrays, because they're easier. */

@synthesize dirty;
@synthesize chars;
@synthesize styles;

- (id) init {
	self = [super init];
	
	if (self) {
		dirty = YES;
		width = 0;
		maxwidth = 80;
		chars = (glui32 *)malloc(maxwidth * sizeof(glui32));
		styles = (glui32 *)malloc(maxwidth * sizeof(glui32));
		if (!chars || !styles)
			[NSException raise:@"GlkException" format:@"unable to allocate chars or styles for grid line"];
	}
	
	return self;
}

- (void) dealloc {
	if (chars) {
		free(chars);
		chars = NULL;
	}
	if (styles) {
		free(styles);
		styles = NULL;
	}
	[super dealloc];
}


- (int) width {
	return width;
}

- (void) setWidth:(int)val {
	if (width == val)
		return;
	if (val > maxwidth) {
		maxwidth = val*2;
		chars = (glui32 *)reallocf(chars, maxwidth * sizeof(glui32));
		styles = (glui32 *)reallocf(chars, maxwidth * sizeof(glui32));
		if (!chars || !styles)
			[NSException raise:@"GlkException" format:@"unable to allocate chars or styles for grid line"];
	}
	
	int ix;
	for (ix=width; ix<val; ix++) {
		chars[ix] = ' ';
		styles[ix] = style_Normal;
	}
	
	width = val;
	dirty = YES;
}

- (void) clear {
	int ix;
	for (ix=0; ix<width; ix++) {
		chars[ix] = ' ';
		styles[ix] = style_Normal;
	}
	dirty = YES;
}

@end

@implementation GlkTagString

@synthesize tag;
@synthesize str;

- (id) initWithTag:(NSNumber *)tagval text:(NSString *)strval {
	self = [super init];
	
	if (self) {
		self.tag = tagval;
		self.str = strval;
	}
	
	return self;
}

- (void) dealloc {
	self.tag = nil;
	self.str = nil;
	[super dealloc];
}

@end



