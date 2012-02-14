/* StyledTextView.h: Rich text view class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/


#import <UIKit/UIKit.h>

@class StyleSet;

@interface StyledTextView : UIView {
	CGFloat totalwidth; /* horizontal space available */
	CGFloat wrapwidth; /* totalwidth minus margins */

	StyleSet *styleset;
	
	NSMutableArray *lines; /* Array of GlkStyledLine -- lines (paragraphs) of text */
	NSMutableArray *vlines; /* Array of GlkVisualLine -- the wrapped lines with positional info */
}

@property (nonatomic, retain) NSMutableArray *lines;
@property (nonatomic, retain) NSMutableArray *vlines;
@property (nonatomic, retain) StyleSet *styleset;

- (id) initWithFrame:(CGRect)frame styles:(StyleSet *)stylesval;
- (CGFloat) textHeight;
- (CGFloat) totalHeight;
- (void) setTotalWidth:(CGFloat)totalwidth;
- (void) updateWithLines:(NSArray *)addlines;
- (void) layoutFromLine:(int)fromline;
- (CGRect) placeForInputField;

@end
