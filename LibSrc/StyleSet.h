/* StyleSet.h: A set of font data for a Glk window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <Foundation/Foundation.h>
#include "glk.h"

@interface FontVariants : NSObject

@property (nonatomic, strong) UIFont *normal;
@property (nonatomic, strong) UIFont *italic;
@property (nonatomic, strong) UIFont *bold;

@end

@interface StyleSet : NSObject {
	NSMutableArray *fonts; /* array of UIFonts (or NSNull during initialization) */
	NSMutableArray *colors; /* array UIColors (or NSNull during initialization) */
	CGFloat leading; /* extra space below each line (uniform across all styles) */
	CGSize charbox; /* maximum size of a single rendered character (normal style) (including leading) */
	UIColor *backgroundcolor; /* background color for window */
	UIEdgeInsets margins; /* margin widths around the text */
	CGSize margintotal; /* width = left+right; height = top+bottom */
}

@property (nonatomic, strong) NSMutableArray *fonts;
@property (nonatomic, strong) NSMutableArray *colors;
@property (nonatomic) CGFloat leading;
@property (nonatomic) CGSize charbox;
@property (nonatomic, strong) UIColor *backgroundcolor;
@property (nonatomic) UIEdgeInsets margins;
@property (nonatomic) CGSize margintotal;

+ (StyleSet *) buildForWindowType:(glui32)wintype rock:(glui32)rock;
+ (FontVariants *) fontVariantsForSize:(CGFloat)size name:(NSString *)first, ...;

- (void) completeForWindowType:(glui32)wintype;

@end
