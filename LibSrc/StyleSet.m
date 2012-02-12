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
@synthesize charbox;
@synthesize margins;
@synthesize margintotal;

+ (StyleSet *) buildForWindowType:(glui32)wintype rock:(glui32)rock {
	GlkLibrary *library = [GlkLibrary singleton];
	
	StyleSet *styles = [[[StyleSet alloc] init] autorelease];
	[library.glkdelegate prepareStyles:styles forWindowType:wintype rock:rock];
	[styles completeForWindowType:wintype];

	return styles;
}

+ (FontVariants) fontVariantsForSize:(CGFloat)size family:(NSString *)first, ... {
	FontVariants variants;
	variants.normal = nil;
	variants.italic = nil;
	variants.bold = nil;
	
	//###
	
	return variants;
}

- (id) init {
	self = [super init];
	
	if (self) {
		charbox = CGSizeZero;
		margins = UIEdgeInsetsZero;
		margintotal = CGSizeZero;
		/* We have to malloc this buffer. I tried embedding it as an array of pointers in the StyleSet object, but ObjC threw a hissy-cow. */
		fonts = malloc(sizeof(UIFont*) * style_NUMSTYLES);
		for (int ix=0; ix<style_NUMSTYLES; ix++)
			fonts[ix] = nil;
	}
	
	return self;
}

- (void) dealloc {
	for (int ix=0; ix<style_NUMSTYLES; ix++) {
		if (fonts[ix]) {
			[fonts[ix] release];
			fonts[ix] = nil;
		}
	}
	free(fonts);
	fonts = nil;
	[super dealloc];
}

- (void) completeForWindowType:(glui32)wintype {
	/* Fill in any fonts that were omitted. */
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
					fonts[ix] = fonts[0];
					break;
			}
		}
	}
	
	/* The delegate prepareStyles method filled the array with autoreleased fonts. We retain them now. */
	for (int ix=0; ix<style_NUMSTYLES; ix++) {
		[fonts[ix] retain];
	}
	
	CGSize size;
	size = [@"W" sizeWithFont:fonts[style_Normal]];
	charbox = size;
	size = [@"qld" sizeWithFont:fonts[style_Normal]];
	if (charbox.height < size.height)
		charbox.height = size.height;
	
	margintotal.width = margins.left + margins.right;
	margintotal.height = margins.top + margins.bottom;
}


@end
