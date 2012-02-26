/* StyledTextView.h: Rich text view class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/


#import <UIKit/UIKit.h>

@class StyleSet;
@class GlkVisualLine;

@interface StyledTextView : UIScrollView {
	CGFloat totalheight; /* vertical space available */
	CGFloat totalwidth; /* horizontal space available */
	CGFloat wrapwidth; /* totalwidth minus margins */

	StyleSet *styleset;
	
	int clearcount;
	int firstsline; /* index of the first sline (or 0 if slines is empty) */
	NSMutableArray *slines; /* Array of GlkStyledLine -- lines (paragraphs) of text */
	NSMutableArray *vlines; /* Array of GlkVisualLine -- the wrapped lines with positional info */
	/* The textual range of vlines is always a subset (or equal to) the range of lines. There may be many vlines per line. */
	NSMutableArray *linesviews; /* Array of VisualLinesView -- stripes of vlines. There may be many vlines of linesview. */
	
	BOOL newcontent; /* True if new text has been added recently. This is cleared by the subsequent layoutSubviews. */
	BOOL wasclear; /* True if the new content is *entirely* new -- i.e., the screen was cleared this update. */
	int endvlineseen; /* End of the range of vlines that are known to have been seen. (Or, the index of the first unseen vline.) If this is equal to vlines.count, the whole page is seen. */
	
	BOOL taptracking;
	CGPoint taploc;
	NSTimeInterval taplastat;
	int tapnumber;
}

@property (nonatomic, retain) NSMutableArray *slines;
@property (nonatomic, retain) NSMutableArray *vlines;
@property (nonatomic, retain) NSMutableArray *linesviews;
@property (nonatomic, retain) StyleSet *styleset;

- (id) initWithFrame:(CGRect)frame styles:(StyleSet *)stylesval;
- (void) acceptStyleset:(StyleSet *)stylesval;
- (CGFloat) totalHeight;
- (BOOL) moreToSee;
- (GlkVisualLine *) lineAtPos:(CGFloat)ypos;
- (void) updateWithLines:(NSArray *)uplines dirtyFrom:(int)linesdirtyfrom clearCount:(int)newclearcount;
- (void) uncacheLayoutAndVLines:(BOOL)andvlines;
- (NSMutableArray *) layoutFromLine:(int)startline forward:(BOOL)forward yMax:(CGFloat)ymax;
- (void) sanityCheck;
- (CGRect) placeForInputField;
- (BOOL) pageDown;
- (BOOL) pageToBottom;

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

