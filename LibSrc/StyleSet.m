/* StyleSet.m: A set of font data for a Glk window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/


#import "StyleSet.h"
#import "GlkUtilities.h"

@implementation StyleSet

@synthesize fonts;
@synthesize charbox;
@synthesize marginframe;

- (id) init {
	self = [super init];
	
	if (self) {
		charbox = CGSizeZero;
		marginframe = CGRectZero;
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

/* Set the fonts according to a family and font size. This is not at all usefully flexible, and will be replaced with something else someday. 
*/
- (void) setFontFamily:(NSString *)family size:(CGFloat)fontsize {
	NSArray *fontnames = [UIFont fontNamesForFamilyName:family];
	if (!fontnames || fontnames.count == 0)
		[NSException raise:@"GlkException" format:@"no such font family: %@", family];
	
	UIFont *normalfont = [UIFont fontWithName:family size:fontsize];
		
	UIFont *boldfont = [UIFont fontWithName:[family stringByAppendingString:@"-Bold"] size:fontsize];
	if (!boldfont)
		boldfont = [UIFont fontWithName:[family stringByAppendingString:@"-Heavy"] size:fontsize];
	if (!boldfont)
		boldfont = normalfont;

	UIFont *italicfont = [UIFont fontWithName:[family stringByAppendingString:@"-Italic"] size:fontsize];
	if (!italicfont)
		italicfont = [UIFont fontWithName:[family stringByAppendingString:@"-Oblique"] size:fontsize];
	if (!italicfont)
		italicfont = normalfont;

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
	
	CGSize size;
	size = [@"W" sizeWithFont:fonts[style_Normal]];
	charbox = size;
	size = [@"qld" sizeWithFont:fonts[style_Normal]];
	if (charbox.height < size.height)
		charbox.height = size.height;
	NSLog(@"Measured family %@ (%.1f pt) to have charbox %@", family, fontsize, StringFromSize(charbox));
	
	marginframe.origin.x = 6.0;
	marginframe.origin.y = 4.0;
	marginframe.size.width = 12.0;
	marginframe.size.height = 8.0;
}


@end
