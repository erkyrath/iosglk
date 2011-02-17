/* StyleSet.h: A set of font data for a Glk window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <Foundation/Foundation.h>
#include "glk.h"

@interface StyleSet : NSObject {
	UIFont **fonts; // array[style_NUMSTYLES] of retained UIFonts
}

- (void) setFontFamily:(NSString *)family size:(CGFloat)fontsize;
- (UIFont **)fonts;

@end
