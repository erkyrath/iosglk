/* StyleSet.h: A set of font data for a Glk window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <Foundation/Foundation.h>
#include "glk.h"

typedef struct FontVariants_struct {
	UIFont *normal;
	UIFont *italic;
	UIFont *bold;
} FontVariants;

@interface StyleSet : NSObject {
	UIFont **fonts; /* array[style_NUMSTYLES] of retained UIFonts */
	CGSize charbox; /* maximum size of a single rendered character (normal style) */
	UIColor *backgroundcolor; /* background color for window */
	UIEdgeInsets margins; /* margin widths around the text */
	CGSize margintotal; /* width = left+right; height = top+bottom */
}

@property (nonatomic, readonly) UIFont **fonts;
@property (nonatomic) CGSize charbox;
@property (nonatomic, retain) UIColor *backgroundcolor;
@property (nonatomic) UIEdgeInsets margins;
@property (nonatomic) CGSize margintotal;

+ (StyleSet *) buildForWindowType:(glui32)wintype rock:(glui32)rock;
+ (FontVariants) fontVariantsForSize:(CGFloat)size name:(NSString *)first, ...;

- (void) completeForWindowType:(glui32)wintype;

@end
