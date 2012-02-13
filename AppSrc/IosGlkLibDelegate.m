/* IosGlkLibDelegate.m: Library delegate protocol -- default implementation
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import "IosGlkLibDelegate.h"
#import "StyleSet.h"

@implementation DefaultGlkLibDelegate

DefaultGlkLibDelegate *_DefaultGlkLibDelegate_singleton = nil; // retained forever

+ (DefaultGlkLibDelegate *) singleton {
	if (!_DefaultGlkLibDelegate_singleton)
		_DefaultGlkLibDelegate_singleton = [[DefaultGlkLibDelegate alloc] init]; // retained
	return _DefaultGlkLibDelegate_singleton;
}

- (void) prepareStyles:(StyleSet *)styles forWindowType:(glui32)wintype rock:(glui32)rock {
	if (wintype == wintype_TextGrid) {
		styles.margins = UIEdgeInsetsMake(4, 6, 4, 6);
		
		FontVariants variants = [StyleSet fontVariantsForSize:14 name:@"Courier", nil];
		styles.fonts[style_Normal] = variants.normal;
		styles.fonts[style_Emphasized] = variants.italic;
		styles.fonts[style_Preformatted] = variants.normal;
		styles.fonts[style_Header] = variants.bold;
		styles.fonts[style_Subheader] = variants.bold;
		styles.fonts[style_Alert] = variants.italic;
		styles.fonts[style_Note] = variants.italic;
		
	}
	else {
		styles.margins = UIEdgeInsetsMake(4, 6, 4, 6);
		
		FontVariants variants = [StyleSet fontVariantsForSize:14 name:@"HelveticaNeue", @"Helvetica", nil];
		styles.fonts[style_Normal] = variants.normal;
		styles.fonts[style_Emphasized] = variants.italic;
		styles.fonts[style_Preformatted] = [UIFont fontWithName:@"Courier" size:14];
		styles.fonts[style_Header] = variants.bold;
		styles.fonts[style_Subheader] = variants.bold;
		styles.fonts[style_Alert] = variants.italic;
		styles.fonts[style_Note] = variants.italic;
		
	}
}

- (CGSize) interWindowSpacing {
	return CGSizeMake(4, 4);
}

- (CGRect) adjustFrame:(CGRect)rect {
	return rect;
}

@end

