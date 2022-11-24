/* GlkWinGridView.h: Glk textgrid window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>
#import "GlkWindowView.h"

@class GlkStyledLine;

@interface GlkWinGridView : GlkWindowView <UITextViewDelegate>

@property (nonatomic, strong) UITextView *textview;

@end
