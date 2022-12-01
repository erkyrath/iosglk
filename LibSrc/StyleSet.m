/* StyleSet.m: A set of font data for a Glk window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/


#import "StyleSet.h"
#import "GlkLibrary.h"
#import "GlkUtilities.h"
#import "IosGlkLibDelegate.h"

@implementation StyleSet

/* Generate a styleset appropriate to the given window (as identified by window type and rock). The glkdelegate handles this.
 
	Pedantically, we should note that this is invoked from both the VM and UI threads.
 */
+ (StyleSet *) buildForWindowType:(glui32)wintype rock:(glui32)rock {
	GlkLibrary *library = [GlkLibrary singleton];
	
	StyleSet *styles = [[StyleSet alloc] init];
	[library.glkdelegate prepareStyles:styles forWindowType:wintype rock:rock];
	[styles completeForWindowType:wintype];

	return styles;
}

/* Given a list of font names, try to locate a set of normal/bold/italic fonts that match.
 
	This will use the first listed font which is available. The list of font names must be nil-terminated.
 
	This returns a struct containing UIFont objects.
 */
+ (FontVariants) fontVariantsForSize:(CGFloat)size name:(NSString *)first, ... {
	FontVariants variants;
	variants.normal = nil;
	variants.italic = nil;
	variants.bold = nil;
	
	va_list arglist;
    va_start(arglist, first);
	for (NSString *family = first; family; family = va_arg(arglist, NSString *)) {
		
		/* Some special cases first! */
		if ([family isEqualToString:@"Times"] || [family isEqualToString:@"Times New Roman"]) {
			variants.normal = [UIFont fontWithName:@"TimesNewRomanPSMT" size:size];
			if (!variants.normal)
				continue;
			variants.italic = [UIFont fontWithName:@"TimesNewRomanPS-ItalicMT" size:size];
			variants.bold = [UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:size];
			break;
		}
		if ([family isEqualToString:@"Helvetica Neue"]) {
			variants.normal = [UIFont fontWithName:@"HelveticaNeue" size:size];
			if (!variants.normal)
				continue;
			variants.bold = [UIFont fontWithName:@"HelveticaNeue-Bold" size:size];
			variants.italic = [UIFont fontWithName:@"HelveticaNeue-Italic" size:size];
			/* iOS 3 had HelveticaNeue and Bold, but not Italic. Substitute original Helvetica-Oblique. */
			if (!variants.italic)
				variants.italic = [UIFont fontWithName:@"Helvetica-Oblique" size:size];
			break;
		}
		if ([family isEqualToString:@"Hoefler Text"]) {
			variants.normal = [UIFont fontWithName:@"HoeflerText-Regular" size:size];
			if (!variants.normal)
				continue;
			variants.bold = [UIFont fontWithName:@"HoeflerText-Black" size:size];
			variants.italic = [UIFont fontWithName:@"HoeflerText-Italic" size:size];
			break;
		}
		
		UIFont *normalfont = [UIFont fontWithName:family size:size];
		if (!normalfont)
			continue;
		
		UIFont *italicfont = [UIFont fontWithName:[family stringByAppendingString:@"-Italic"] size:size];
		if (!italicfont)
			italicfont = [UIFont fontWithName:[family stringByAppendingString:@"-Oblique"] size:size];
		if (!italicfont)
			italicfont = normalfont;
		
		UIFont *boldfont = [UIFont fontWithName:[family stringByAppendingString:@"-Bold"] size:size];
		if (!boldfont)
			boldfont = [UIFont fontWithName:[family stringByAppendingString:@"-Heavy"] size:size];
		if (!boldfont)
			boldfont = normalfont;
		
		variants.normal = normalfont;
		variants.italic = italicfont;
		variants.bold = boldfont;
		break;
	}
	va_end(arglist);
	
	if (!variants.normal) {
		variants.normal = [UIFont systemFontOfSize:size];
		variants.italic = [UIFont italicSystemFontOfSize:size];
		variants.bold = [UIFont boldSystemFontOfSize:size];
	}
	
	return variants;
}

- (instancetype) init {
	self = [super init];
	
	if (self) {
        _charbox = CGSizeZero;
		_margins = UIEdgeInsetsZero;
		_leading = 0;
		_margintotal = CGSizeZero;
		self.backgroundcolor = [UIColor whiteColor];
		_fonts = [[NSMutableArray alloc] initWithCapacity:style_NUMSTYLES];
		for (int ix=0; ix<style_NUMSTYLES; ix++)
            _fonts[ix] = [NSNull null];
        _colors = [[NSMutableArray alloc] initWithCapacity:style_NUMSTYLES];
		for (int ix=0; ix<style_NUMSTYLES; ix++)
            _colors[ix] = [NSNull null];
        _gridattributes = [[NSMutableArray<NSDictionary *> alloc] initWithCapacity:style_NUMSTYLES];
        _bufferattributes  = [[NSMutableArray<NSDictionary *> alloc] initWithCapacity:style_NUMSTYLES];
	}
	
	return self;
}

- (void) completeForWindowType:(glui32)wintype {
	/* Fill in any fonts and colors that were omitted. */

    NSMutableArray *attrarray = [[NSMutableArray<NSDictionary*> alloc] initWithCapacity:style_NUMSTYLES];

	for (int ix=0; ix<style_NUMSTYLES; ix++) {
        if ([_fonts[ix] isEqual:[NSNull null]]) {
			switch (ix) {
				case style_Normal:
					if (wintype == wintype_TextBuffer)
                        _fonts[ix] = [UIFont systemFontOfSize:14];
					else
						_fonts[ix] = [UIFont fontWithName:@"Courier" size:14];
					break;
				default:
					_fonts[ix] = _fonts[style_Normal];
					break;
			}
		}

        if ([_colors[ix] isEqual:[NSNull null]]) {
			switch (ix) {
				case style_Normal:
					_colors[ix] = [UIColor blackColor];
					break;
				default:
					_colors[ix] = _colors[style_Normal];
					break;
			}
		}

        NSMutableParagraphStyle *parastyle = [NSParagraphStyle defaultParagraphStyle].mutableCopy;
        parastyle.headIndent = 0;
        parastyle.firstLineHeadIndent = 0;
        //    parastyle.maximumLineHeight = self.styleset.charbox.height;

        parastyle.lineSpacing = self.leading;
        NSDictionary *attributes = @{ @"GlkStyle": @(ix),
                                      NSFontAttributeName: _fonts[ix],
                                      NSForegroundColorAttributeName: _colors[ix],
                                      NSParagraphStyleAttributeName: parastyle };
        [attrarray addObject:attributes];
	}

    if (wintype == wintype_TextGrid)
        _gridattributes = attrarray;
    else
        _bufferattributes = attrarray;

    NSDictionary *attributes = attrarray[style_Normal];
	
	CGSize size = [@"W" sizeWithAttributes:attributes];
	_charbox = size;
	size = [@"qld" sizeWithAttributes:attributes];
	if (_charbox.height < size.height)
		_charbox.height = size.height;
	
	_charbox.height += _leading;
	
	_margintotal.width = _margins.left + _margins.right;
	_margintotal.height = _margins.top + _margins.bottom;
}

@end
