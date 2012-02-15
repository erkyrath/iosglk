/* StyledTextView.h: Rich text view class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/


#import <UIKit/UIKit.h>

@class StyleSet;

@interface StyledTextView : UIScrollView {
	CGFloat totalwidth; /* horizontal space available */
	CGFloat wrapwidth; /* totalwidth minus margins */

	StyleSet *styleset;
	
	NSMutableArray *lines; /* Array of GlkStyledLine -- lines (paragraphs) of text */
	NSMutableArray *vlines; /* Array of GlkVisualLine -- the wrapped lines with positional info */
	/* The range of vlines is always a subset (or equal to) the range of lines. There may be many vlines per line. */
	NSMutableArray *linesviews; /* Array of VisualLinesView -- stripes of vlines. There may be many vlines of linesview. */
}

@property (nonatomic, retain) NSMutableArray *lines;
@property (nonatomic, retain) NSMutableArray *vlines;
@property (nonatomic, retain) NSMutableArray *linesviews;
@property (nonatomic, retain) StyleSet *styleset;

- (id) initWithFrame:(CGRect)frame styles:(StyleSet *)stylesval;
- (CGFloat) textHeight;
- (CGFloat) totalHeight;
//###- (void) setTotalWidth:(CGFloat)totalwidth;
- (void) updateWithLines:(NSArray *)addlines;
- (NSMutableArray *) layoutFromLine:(int)startline forward:(BOOL)forward yStart:(CGFloat)ystart yMax:(CGFloat)ymax;
- (CGRect) placeForInputField;

@end


@interface VisualLinesView : UIView {
	NSArray *vlines; /* Array of GlkVisualLine */
	StyleSet *styleset;
	CGFloat ytop; /* The ypos of the first line */
	CGFloat ybottom; /* The bottom of the last line */
	CGFloat height; /* The total height of all lines */
	int vlinestart; /* The index of the first line */
	int vlineend; /* The index after the last line */
}

@property (nonatomic, retain) NSArray *vlines;
@property (nonatomic, retain) StyleSet *styleset;
@property (nonatomic) CGFloat ytop;
@property (nonatomic) CGFloat ybottom;
@property (nonatomic) CGFloat height;
@property (nonatomic) int vlinestart;
@property (nonatomic) int vlineend;

- (id) initWithFrame:(CGRect)frame styles:(StyleSet *)styleset vlines:(NSArray *)vlines;

@end

