/* PopMenuView.h: Base class for on-screen pop-up menus
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import <UIKit/UIKit.h>

@class GlkFrameView;

@interface PopMenuView : UIView {
	UIView *frameview;
	UIView *content;
	UIView *decor;
	UIView *faderview;
	UIEdgeInsets framemargins; /* The distance around the content view on all sides */
	CGRect buttonrect; /* The bounds of the button that launched this menu */
	int vertalign; /* 1: below the buttonrect; -1: above it; 0: centered */
	int horizalign; /* 1: to the right of the buttonrect; -1: to the left; 0: centered */
}

@property (nonatomic, retain) IBOutlet UIView *frameview;
@property (nonatomic, retain) IBOutlet UIView *content;
@property (nonatomic, retain) IBOutlet UIView *decor;
@property (nonatomic, retain) IBOutlet UIView *faderview;
@property (nonatomic) UIEdgeInsets framemargins;
@property (nonatomic, readonly) CGRect buttonrect;
@property (nonatomic, readonly) int vertalign;
@property (nonatomic, readonly) int horizalign;

- (id) initWithFrame:(CGRect)frame centerInFrame:(CGRect)rect;
- (id) initWithFrame:(CGRect)frame buttonFrame:(CGRect)rect belowButton:(BOOL)below;
- (id) initWithFrame:(CGRect)frame buttonFrame:(CGRect)rect vertAlign:(int)vertval horizAlign:(int)horval;
- (GlkFrameView *) superviewAsFrameView;
- (NSString *) bottomDecorNib;
- (void) loadContent;
- (void) resizeContentTo:(CGSize)size animated:(BOOL)animated;
- (void) willRemove;

@end
