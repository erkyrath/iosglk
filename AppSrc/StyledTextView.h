/* StyledTextView.h: Rich text view class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/


#import <UIKit/UIKit.h>
#import "GlkWindowView.h"

@class StyleSet;
@class GlkVisualLine;
@class TextSelectView;
@class CmdTextField;

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
	BOOL wasrefresh; /* True if the new content is really not new, but the textview is new and hasn't seen it before. */
	CGFloat idealcontentheight; /* What we want the contentSize.height to be -- the height of the text content. The actual scrollview's value may be larger, due to resizing errors that we (grudgingly) accomodate. */
	BOOL wasatbottom; /* True if the text was scrolled all the way down (as of the most recent update). */
	int endvlineseen; /* End of the range of vlines that are known to have been seen. (Or, the index of the first unseen vline.) If this is equal to vlines.count, the whole page is seen. */
	
	int selectvstart; /* index of the first selected vline (or -1 if no selection) */
	int selectvend; /* index of the last selected vline + 1 */
	CGRect selectionarea; /* only meaningful if a selection exists */
	TextSelectView *selectionview;
	
	BOOL taptracking;
	SelDragMode tapseldragging;
	CGPoint taploc;
	NSTimeInterval taplastat;
	int tapnumber;
}

@property (nonatomic, retain) NSMutableArray *slines;
@property (nonatomic, retain) NSMutableArray *vlines;
@property (nonatomic, retain) NSMutableArray *linesviews;
@property (nonatomic, retain) StyleSet *styleset;
@property (nonatomic, retain) TextSelectView *selectionview;
@property (nonatomic, readonly) CGRect selectionarea;

- (id) initWithFrame:(CGRect)frame styles:(StyleSet *)stylesval;
- (UIScrollView *) inputholder;
- (CmdTextField *) inputfield;
- (void) acceptStyleset:(StyleSet *)stylesval;
- (CGFloat) totalHeight;
- (BOOL) moreToSee;
- (GlkVisualLine *) lineAtPos:(CGFloat)ypos;
- (void) updateWithLines:(NSArray *)uplines dirtyFrom:(int)linesdirtyfrom clearCount:(int)newclearcount refresh:(BOOL)refresh;
- (void) uncacheLayoutAndVLines:(BOOL)andvlines;
- (NSMutableArray *) layoutFromLine:(int)startline forward:(BOOL)forward yMax:(CGFloat)ymax;
- (void) sanityCheck;
- (CGRect) placeForInputField;
- (BOOL) pageDown:(id)sender;
- (BOOL) pageToBottom;
- (void) clearTouchTracking;
- (BOOL) anySelection;
- (void) clearSelection;
- (void) showSelectionMenu;

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

