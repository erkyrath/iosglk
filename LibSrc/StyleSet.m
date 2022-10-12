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

@synthesize fonts;
@synthesize colors;
@synthesize leading;
@synthesize charbox;
@synthesize backgroundcolor;
@synthesize margins;
@synthesize margintotal;

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
 
	This returns a struct containing non-retained (autoreleased) UIFont objects.
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

- (id) init {
	self = [super init];
	
	if (self) {
		charbox = CGSizeZero;
		margins = UIEdgeInsetsZero;
		leading = 0;
		margintotal = CGSizeZero;
		self.backgroundcolor = [UIColor whiteColor];
		/* We have to malloc these buffers. I tried embedding it as an array of pointers in the StyleSet object, but ObjC threw a hissy-cow. */
		fonts = [[NSMutableArray alloc] initWithCapacity:style_NUMSTYLES];
		for (int ix=0; ix<style_NUMSTYLES; ix++)
			fonts[ix] = [UIFont systemFontOfSize:14];
        colors = [[NSMutableArray alloc] initWithCapacity:style_NUMSTYLES];
		for (int ix=0; ix<style_NUMSTYLES; ix++)
			colors[ix] = [UIColor blackColor];
	}
	
	return self;
}

- (void) completeForWindowType:(glui32)wintype {
	/* Fill in any fonts and colors that were omitted. Use autoreleased references at this point. */
	
	for (int ix=0; ix<style_NUMSTYLES; ix++) {
		if (!fonts[ix]) {
			switch (ix) {
				case style_Normal:
					if (wintype == wintype_TextBuffer)
						fonts[ix] = [UIFont systemFontOfSize:14];
					else
						fonts[ix] = [UIFont fontWithName:@"Courier" size:14];
					break;
				default:
					fonts[ix] = fonts[style_Normal];
					break;
			}
		}
		
		if (!colors[ix]) {
			switch (ix) {
				case style_Normal:
					colors[ix] = [UIColor blackColor];
					break;
				default:
					colors[ix] = colors[style_Normal];
					break;
			}
		}
	}
	
	/* The delegate prepareStyles method (also the code above) filled the arrays with autoreleased fonts and colors. We retain them now. */
	for (int ix=0; ix<style_NUMSTYLES; ix++) {
		fonts[ix];
		colors[ix];
	}
	
	CGSize size;
    size = [@"W" sizeWithAttributes:@{NSFontAttributeName:fonts[style_Normal]}];
	charbox = size;
	size = [@"qld" sizeWithAttributes:@{NSFontAttributeName:fonts[style_Normal]}];
	if (charbox.height < size.height)
		charbox.height = size.height;
	
	charbox.height += leading;
	
	margintotal.width = margins.left + margins.right;
	margintotal.height = margins.top + margins.bottom;
}


@end
