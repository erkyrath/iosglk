/* StyleSet.h: A set of font data for a Glk window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <Foundation/Foundation.h>
#include "glk.h"

@interface StyleSet : NSObject {
	UIFont **fonts; /* array[style_NUMSTYLES] of retained UIFonts */
	CGSize charbox; /* maximum size of a single rendered character (normal style) */
	UIEdgeInsets margins; /* margin widths around the text */
	CGSize margintotal; /* width = left+right; height = top+bottom */
}

@property (nonatomic, readonly) UIFont **fonts;
@property (nonatomic) CGSize charbox;
@property (nonatomic) UIEdgeInsets margins;
@property (nonatomic) CGSize margintotal;

- (void) setFontFamily:(NSString *)family size:(CGFloat)fontsize;

@end
