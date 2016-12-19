/* StyleSet.h: A set of font data for a Glk window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <Foundation/Foundation.h>
#include "glk.h"

@interface FontVariants : NSObject {
	UIFont *normal;
	UIFont *italic;
	UIFont *bold;
}

@end

@interface StyleSet : NSObject {
	NSArray<UIFont *> *fonts; /* array[style_NUMSTYLES] of retained UIFonts (malloced) */
	NSArray<UIColor *> *colors; /* array[style_NUMSTYLES] of retained UIColors (malloced) */
	CGFloat leading; /* extra space below each line (uniform across all styles) */
	CGSize charbox; /* maximum size of a single rendered character (normal style) (including leading) */
	UIColor *backgroundcolor; /* background color for window */
	UIEdgeInsets margins; /* margin widths around the text */
	CGSize margintotal; /* width = left+right; height = top+bottom */
}

@property (nonatomic, readonly) NSArray<UIFont *> *fonts;
@property (nonatomic, readonly) NSArray<UIColor *> *colors;
@property (nonatomic) CGFloat leading;
@property (nonatomic) CGSize charbox;
@property (nonatomic, retain) UIColor *backgroundcolor;
@property (nonatomic) UIEdgeInsets margins;
@property (nonatomic) CGSize margintotal;

+ (StyleSet *) buildForWindowType:(glui32)wintype rock:(glui32)rock;
+ (FontVariants *) fontVariantsForSize:(CGFloat)size name:(NSString *)first, ...;

- (void) completeForWindowType:(glui32)wintype;

@end
