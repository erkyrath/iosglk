/* GlkWinGridView.h: Glk textgrid window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>
#import "GlkWindowView.h"

@class TextSelectView;
@class GlkStyledLine;

@interface GlkWinGridView : GlkWindowView {
	NSMutableArray *lines; /* array of GlkStyledLine */

	int selectvstart; /* index of the first selected line (or -1 if no selection) */
	int selectvend; /* index of the last selected line + 1 */
	CGRect selectionarea; /* only meaningful if a selection exists */
	TextSelectView *selectionview;
	
	BOOL taptracking;
	SelDragMode tapseldragging;
	CGPoint taploc;
	NSTimeInterval taplastat;
	int tapnumber;
}

@property (nonatomic, retain) NSMutableArray *lines;
@property (nonatomic, retain) TextSelectView *selectionview;

- (GlkStyledLine *) lineAtPos:(CGFloat)ypos;

@end
