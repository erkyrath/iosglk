/* GlkWinGridView.h: Glk textgrid window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>
#import "GlkWindowView.h"

typedef enum GSelDragMode_enum {
	SelDrag_none = 0,
	SelDrag_paragraph = 1,
	SelDrag_topedge = 2,
	SelDrag_bottomedge = 3,
} GSelDragMode;

@class TextSelectView;

@interface GlkWinGridView : GlkWindowView {
	NSMutableArray *lines; /* array of GlkStyledLine */

	int selectvstart; /* index of the first selected line (or -1 if no selection) */
	int selectvend; /* index of the last selected line + 1 */
	CGRect selectionarea; /* only meaningful if a selection exists */
	TextSelectView *selectionview;
	
	BOOL taptracking;
	GSelDragMode tapseldragging;
	CGPoint taploc;
	NSTimeInterval taplastat;
	int tapnumber;
}

@property (nonatomic, retain) NSMutableArray *lines;
@property (nonatomic, retain) TextSelectView *selectionview;

@end
