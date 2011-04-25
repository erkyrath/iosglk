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
	CGRect marginframe; /* abusing the concept of a CGRect -- read "width" as the total of left+right margins, and "x" as the left margin */
}

@property (nonatomic, readonly) UIFont **fonts;
@property (nonatomic) CGSize charbox;
@property (nonatomic) CGRect marginframe;

- (void) setFontFamily:(NSString *)family size:(CGFloat)fontsize;

@end
