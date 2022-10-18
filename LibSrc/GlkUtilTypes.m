/* GlkUtilTypes.m: Miscellaneous objc classes
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	Some utility classes that are small and boring and don't fit anywhere else.
*/

#import "GlkUtilTypes.h"
#import "GlkAccessTypes.h"
#import "StyleSet.h"

@implementation GlkStyledLine
/* GlkStyledLine: Represents a line of text. (Used in a few different places.)
 
	It's just an array of GlkStyledStrings, with an additional optional flag saying "This starts a new line" or "This starts a new page." (Consider either to be a newline at the *beginning* of the GlkStyledLine, possibly with page-breaking behavior.)
*/

@synthesize index;
@synthesize status;
@synthesize arr;
@synthesize concatline;
@synthesize accessel;

+ (BOOL) supportsSecureCoding {
    return YES;
}

- (instancetype) initWithIndex:(int)indexval {
	return [self initWithIndex:indexval status:linestat_Continue];
}

- (instancetype) initWithIndex:(int)indexval status:(GlkStyledLineStatus) statusval {
	self = [super init];
	
	if (self) {
		index = indexval;
		status = statusval;
		self.arr = [NSMutableArray arrayWithCapacity:16];
	}
	
	return self;
}

- (instancetype) initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        index = [decoder decodeIntForKey:@"index"];
        status = [decoder decodeIntForKey:@"status"];
        self.arr = [decoder decodeObjectForKey:@"arr"];
    }
    return self;
}

/* Standard copy method. Returns a retained object which is a (shallow) copy. (Skip the cached elements.) */
- (id) copyWithZone:(NSZone *)zone {
	GlkStyledLine *copy = [[GlkStyledLine allocWithZone:zone] init];
	copy.index = index;
	copy.status = status;
	copy.arr = arr;
	return copy;
}

- (void) dealloc {
	if (accessel) {
		accessel.line = nil; /* clear the weak parent link */
	}
}

- (void) encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeInt:index forKey:@"index"];
	if (status)
		[encoder encodeInt:status forKey:@"status"];
	[encoder encodeObject:arr forKey:@"arr"];
}

- (NSString *) description {
	NSString *statstr;
	switch (status) {
		case linestat_Continue:
			statstr = @"cont";
			break;
		case linestat_NewLine:
			statstr = @"newline";
			break;
		case linestat_ClearPage:
			statstr = @"clear";
			break;
		default:
			statstr = @"???";
			break;
	}
	
	return [NSString stringWithFormat:@"<GlkStyledLine (%d/%@) '%@'>", index, statstr, self.concatLine];
}

- (NSString *) concatLine {
	if (!concatline) {
		NSMutableString *tmpstr = [NSMutableString stringWithCapacity:80];
		for (GlkStyledString *sstr in arr) {
			[tmpstr appendString:sstr.str];
		}
		self.concatline = [NSString stringWithString:tmpstr];
	}
	return concatline;
}

- (NSString *) wordAtPos:(CGFloat)xpos styles:(StyleSet *)styleset {
	return [self wordAtPos:xpos styles:styleset inBox:nil];
}

- (NSString *) wordAtPos:(CGFloat)xpos styles:(StyleSet *)styleset inBox:(CGRect *)boxref {
	int concatlen = self.concatLine.length;
	CGFloat leftmargin = styleset.margins.left;
	CGFloat charwidth = styleset.charbox.width;
	
	if (concatlen == 0) {
		if (boxref)
			*boxref = CGRectNull;
		return nil;
	}
	
	int pos = (int)((xpos - leftmargin) / charwidth);
	pos = MIN(concatlen, pos);
	pos = MAX(pos, 0);
	
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
		CGFloat topmargin = styleset.margins.top;
		CGFloat charheight = styleset.charbox.height;
		*boxref = CGRectMake(leftmargin+wdstart*charwidth, topmargin+index*charheight, charwidth*(wdend-wdstart), charheight);
	}
	
	NSRange range;
	range.location = wdstart;
	range.length = wdend - wdstart;
	return [line substringWithRange:range];
}

- (GlkAccStyledLine *) accessElementInContainer:(GlkWinGridView *)container {
	if (!accessel) {
		self.accessel = [GlkAccStyledLine buildForLine:self container:container];
	}
	return accessel;
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

+ (BOOL) supportsSecureCoding {
    return YES;
}

- (instancetype) initWithText:(NSString *)initstr style:(glui32)initstyle {
	self = [super init];
	
	if (self) {
		self.str = initstr;
		style = initstyle;
		ismutable = NO;
		pos = 0;
	}
	
	return self;
}

- (instancetype) initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        self.str = [decoder decodeObjectForKey:@"str"];
        style = [decoder decodeInt32ForKey:@"style"];
        pos = [decoder decodeIntForKey:@"pos"];
        ismutable = NO;
    }
	return self;
}


- (void) encodeWithCoder:(NSCoder *)encoder {
	if (ismutable)
		[self freeze];
	[encoder encodeObject:str forKey:@"str"];
	if (style != 0)
		[encoder encodeInt32:style forKey:@"style"];
	if (pos != 0)
		[encoder encodeInt:pos forKey:@"pos"];
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
/* GlkVisualLine: A laid-out line in a text buffer view. */

@synthesize styleset;
@synthesize arr;
@synthesize concatline;
@synthesize letterpos;
@synthesize ypos;
@synthesize height;
@synthesize xstart;
@synthesize vlinenum;
@synthesize linenum;
@synthesize accessel;

- (instancetype) initWithStrings:(NSArray *)strings styles:(StyleSet *)styles {
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
	if (accessel) {
		accessel.line = nil; /* clear the weak parent link */
	}
	if (letterpos) {
		free(letterpos);
		letterpos = nil;
	}
}

- (CGFloat) bottom {
	return ypos + height;
}

- (CGFloat) right {
	if (right < 0) {
		NSMutableArray<UIFont *> *fonts = styleset.fonts;
		CGFloat ptx = xstart;
		for (GlkVisualString *vwd in arr) {
			UIFont *font = fonts[vwd.style];
            CGSize wordsize = [vwd.str sizeWithAttributes:@{NSFontAttributeName:font}];
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
        size_t mallocsize = sizeof(CGFloat) * (1+concatlen);
		letterpos = (CGFloat *)malloc(mallocsize);
        bzero(letterpos, mallocsize);
		
		NSMutableArray<UIFont *> *fonts = styleset.fonts;
		
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
                CGSize wordsize = [wdtext sizeWithAttributes:@{NSFontAttributeName:sfont}];
				wdxpos = wdxstart+wordsize.width;
				if (pos+ix <= concatlen) {
					DEBUG_PARANOID_ASSERT((pos+ix <= concatlen), @"GlkVisualLine: letterpos overflow");
					letterpos[pos+ix] = wdxpos;
				}
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

- (GlkAccVisualLine *) accessElementInContainer:(StyledTextView *)container {
	if (!accessel) {
		self.accessel = [GlkAccVisualLine buildForLine:self container:container];
	}
	return accessel;
}

@end


@implementation GlkVisualString
/* GlkVisualString: A single string, with a single style. */

@synthesize str;
@synthesize style;

- (instancetype) initWithText:(NSString *)initstr style:(glui32)initstyle {
	self = [super init];
	
	if (self) {
		self.str = initstr;
		style = initstyle;
	}
	
	return self;
}


@end


@implementation GlkGridLine
/* GlkGridLine: Represents one line of a text grid. (This is used in the GlkWindowGrid object, not in the view.) 
 
	This contains nasty C arrays, because they're easier. */

@synthesize dirty;
@synthesize chars;
@synthesize styles;

+ (BOOL) supportsSecureCoding {
    return YES;
}

- (instancetype) init {
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

- (instancetype) initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        dirty = YES; // when loaded, all dirty
        width = [decoder decodeIntForKey:@"width"];
        maxwidth = [decoder decodeIntForKey:@"maxwidth"];
        
        chars = (glui32 *)malloc(maxwidth * sizeof(glui32));
        styles = (glui32 *)malloc(maxwidth * sizeof(glui32));
        for (int ix=0; ix<maxwidth; ix++) {
            chars[ix] = ' ';
            styles[ix] = style_Normal;
        }
        
        NSUInteger len;
        uint8_t *tmpchars = (uint8_t *)[decoder decodeBytesForKey:@"chars" returnedLength:&len];
        if (tmpchars) {
            if (len > maxwidth * sizeof(glui32))
                len = maxwidth * sizeof(glui32);
            memcpy(chars, tmpchars, len);
        }
        
        uint8_t *tmpstyles = (uint8_t *)[decoder decodeBytesForKey:@"styles" returnedLength:&len];
        if (tmpstyles) {
            if (len > maxwidth * sizeof(glui32))
                len = maxwidth * sizeof(glui32);
            memcpy(styles, tmpstyles, len);
        }
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
}

- (void) encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeInt:width forKey:@"width"];
	[encoder encodeInt:maxwidth forKey:@"maxwidth"];
	if (chars)
		[encoder encodeBytes:(const uint8_t *)chars length:(maxwidth * sizeof(glui32)) forKey:@"chars"];
	if (styles)
		[encoder encodeBytes:(const uint8_t *)styles length:(maxwidth * sizeof(glui32)) forKey:@"styles"];
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
		DEBUG_PARANOID_ASSERT((ix < maxwidth), @"GlkGridLine: char/style overflow");
		chars[ix] = ' ';
		styles[ix] = style_Normal;
	}
	
	width = val;
	dirty = YES;
}

- (void) clear {
	int ix;
	for (ix=0; ix<width; ix++) {
		DEBUG_PARANOID_ASSERT((ix < maxwidth), @"GlkGridLine: char/style overflow");
		chars[ix] = ' ';
		styles[ix] = style_Normal;
	}
	dirty = YES;
}

@end

@implementation GlkTagString

@synthesize tag;
@synthesize str;

- (instancetype) initWithTag:(NSNumber *)tagval text:(NSString *)strval {
	self = [super init];
	
	if (self) {
		self.tag = tagval;
		self.str = strval;
	}
	
	return self;
}


@end



