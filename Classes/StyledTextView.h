/* StyledTextView.h: Rich text view class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/


#import <UIKit/UIKit.h>


@interface StyledTextView : UIView {
	CGFloat wrapwidth;
	
	NSMutableArray *lines; /* Array of GlkStyledLine -- lines (paragraphs) of text */
	NSMutableArray *vlines; /* Array of GlkVisualLine -- the wrapped lines with positional info */
}

@property (nonatomic, retain) NSMutableArray *lines;
@property (nonatomic, retain) NSMutableArray *vlines;

- (CGFloat) totalHeight;
- (void) updateWithLines:(NSArray *)addlines;
- (void) layoutFromLine:(int)fromline;

@end
