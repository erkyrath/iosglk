/* StyleSet.m: A set of font data for a Glk window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/


#import "StyleSet.h"


@implementation StyleSet

- (id) init {
	self = [super init];
	
	if (self) {
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

/* Set the fonts according to a family and font size. This is not at all usefully flexible, and will be replaced with something else someday. 
*/
- (void) setFontFamily:(NSString *)family size:(CGFloat)fontsize {
	NSArray *fontnames = [UIFont fontNamesForFamilyName:family];
	if (!fontnames || fontnames.count == 0)
		[NSException raise:@"GlkException" format:@"no such font family: %@", family];
		
	/* This way of locating the bold and italic fonts in the family is ridiculous, of course. */
	UIFont *normalfont = nil;
	UIFont *boldfont = nil;
	UIFont *italicfont = nil;
	for (NSString *fontname in fontnames) {
		BOOL isbold = NO;
		BOOL isital = NO;
		NSRange range;
		range = [fontname rangeOfString:@"Bold"];
		if (range.location != NSNotFound)
			isbold = YES;
		range = [fontname rangeOfString:@"Italic"];
		if (range.location != NSNotFound)
			isital = YES;
		range = [fontname rangeOfString:@"Oblique"];
		if (range.location != NSNotFound)
			isital = YES;
		if (!normalfont && !isbold && !isital)
			normalfont = [UIFont fontWithName:fontname size:fontsize];
		if (!boldfont && isbold && !isital)
			boldfont = [UIFont fontWithName:fontname size:fontsize];
		if (!italicfont && !isbold && isital)
			italicfont = [UIFont fontWithName:fontname size:fontsize];
	}
	
	if (!normalfont || !boldfont || !italicfont)
		[NSException raise:@"GlkException" format:@"font family lacks basic variants: %@", family];
		
	fonts[style_Normal] = [normalfont retain];
	fonts[style_Emphasized] = [italicfont retain];
	fonts[style_Preformatted] = [[UIFont fontWithName:@"Courier" size:fontsize] retain];
	fonts[style_Header] = [boldfont retain];
	fonts[style_Subheader] = [boldfont retain];
	fonts[style_Alert] = [italicfont retain];
	fonts[style_Note] = [italicfont retain];
	fonts[style_BlockQuote] = [normalfont retain];
	fonts[style_Input] = [normalfont retain];
	fonts[style_User1] = [normalfont retain];
	fonts[style_User2] = [normalfont retain];
}

- (UIFont **)fonts {
	return fonts;
}


@end
