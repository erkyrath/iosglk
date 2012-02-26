/* GlkUtilTypes.m: Miscellaneous objc classes
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	Some utility classes that are small and boring and don't fit anywhere else.
*/

#import "GlkUtilTypes.h"
#import "StyleSet.h"

@implementation GlkStyledLine
/* GlkStyledLine: Represents a line of text. It's just an array of GlkStyledStrings, with an additional optional flag saying "This starts a new line" or "This starts a new page." (Consider either to be a newline at the *beginning* of the GlkStyledLine, possibly with page-breaking behavior.)
*/

@synthesize index;
@synthesize status;
@synthesize arr;

- (id) initWithIndex:(int)indexval {
	return [self initWithIndex:indexval status:linestat_Continue];
}

- (id) initWithIndex:(int)indexval status:(GlkStyledLineStatus) statusval {
	self = [super init];
	
	if (self) {
		index = indexval;
		status = statusval;
		self.arr = [NSMutableArray arrayWithCapacity:16];
	}
	
	return self;
}

/* Standard copy method. Returns a retained object which is a (shallow) copy. */
- (id) copyWithZone:(NSZone *)zone {
	GlkStyledLine *copy = [[GlkStyledLine allocWithZone:zone] init];
	copy.index = index;
	copy.status = status;
	copy.arr = arr;
	return copy;
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

@synthesize styleset;
@synthesize arr;
@synthesize concatline;
@synthesize letterpos;
@synthesize ypos;
@synthesize height;
@synthesize xstart;
@synthesize vlinenum;
@synthesize linenum;

- (id) initWithStrings:(NSArray *)strings styles:(StyleSet *)styles {
	self = [super init];
	
	if (self) {
		self.arr = [NSArray arrayWithArray:strings];
		self.styleset = styles;
		right = -1;
		letterpos = nil;
	}
	
	return self;
}

- (void) dealloc {
	self.arr = nil;
	self.concatline = nil;
	self.styleset = nil;
	if (letterpos) {
		free(letterpos);
		letterpos = nil;
	}
	[super dealloc];
}

- (CGFloat) bottom {
	return ypos + height;
}

- (CGFloat) right {
	if (right < 0) {
		UIFont **fonts = styleset.fonts;
		CGFloat ptx = xstart;
		for (GlkVisualString *vwd in arr) {
			UIFont *font = fonts[vwd.style];
			CGSize wordsize = [vwd.str sizeWithFont:font];
			ptx += wordsize.width;
		}
		right = ptx;
	}
	return right;
}

- (NSString *) concatLine {
	if (!concatline) {
		NSMutableString *tmpstr = [NSMutableString stringWithCapacity:80];
		for (GlkVisualString *sstr in arr) {
			[tmpstr appendString:sstr.str];
		}
		self.concatline = [NSString stringWithString:tmpstr];
	}
	return concatline;
}

- (NSString *) wordAtPos:(CGFloat)xpos {
	return [self wordAtPos:xpos inBox:nil];
}

- (NSString *) wordAtPos:(CGFloat)xpos inBox:(CGRect *)boxref {
	int concatlen = self.concatLine.length;
	
	if (!letterpos) {
		letterpos = (CGFloat *)malloc(sizeof(CGFloat) * (1+concatlen));
		
		UIFont **fonts = styleset.fonts;
		
		CGFloat wdxstart = xstart;
		CGFloat wdxpos = wdxstart;
		int pos = 0;
		letterpos[0] = wdxstart;
		for (GlkVisualString *sstr in arr) {
			NSString *substr = sstr.str;
			int strlen = substr.length;
			UIFont *sfont = fonts[sstr.style];

			NSRange range;
			range.location = 0;

			for (int ix=1; ix<=strlen; ix++) {
				range.length = ix;
				NSString *wdtext = [substr substringWithRange:range];
				CGSize wordsize = [wdtext sizeWithFont:sfont];
				wdxpos = wdxstart+wordsize.width;
				if (pos+ix <= concatlen)
					letterpos[pos+ix] = wdxpos;
			}
			
			pos += strlen;
			wdxstart = wdxpos;
		}
	}
	
	if (self.right <= xstart || concatlen == 0) {
		if (boxref)
			*boxref = CGRectNull;
		return nil;
	}
	
	CGFloat frac = (xpos-xstart) / (self.right-xstart);
	
	int pos = (int)(concatlen * frac);
	pos = MIN(concatlen, pos);
	pos = MAX(pos, 0);
	
	while (pos > 0 && xpos < letterpos[pos])
		pos--;
	while (pos < concatlen-1 && xpos >= letterpos[pos+1])
		pos++;
	
	int wdstart = pos;
	int wdend = pos;
	NSString *line = self.concatLine;
	
	while (wdstart > 0 && isalnum([line characterAtIndex:wdstart-1]))
		wdstart--;
	while (wdend < concatlen && isalnum([line characterAtIndex:wdend]))
		wdend++;
	
	if (wdstart >= wdend) {
		if (boxref)
			*boxref = CGRectNull;
		return nil;
	}
	
	if (boxref) {
		*boxref = CGRectMake(letterpos[wdstart], ypos, letterpos[wdend]-letterpos[wdstart], height);
	}

	NSRange range;
	range.location = wdstart;
	range.length = wdend - wdstart;
	return [line substringWithRange:range];
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

- (void) dealloc {
	self.str = nil;
	[super dealloc];
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
		styles = (glui32 *)reallocf(styles, maxwidth * sizeof(glui32));
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



