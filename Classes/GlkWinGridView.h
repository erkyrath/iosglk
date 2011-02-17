/* GlkWinGridView.h: Glk textgrid window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>
#import "GlkWindowView.h"

@class StyleSet;

@interface GlkWinGridView : GlkWindowView {
	NSMutableArray *lines; /* array of GlkStyledLine */
	StyleSet *styleset;
}

@property (nonatomic, retain) NSMutableArray *lines;
@property (nonatomic, retain) StyleSet *styleset;

@end
