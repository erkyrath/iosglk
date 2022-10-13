/* PopMenuView.h: Base class for on-screen pop-up menus
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import <UIKit/UIKit.h>

@class GlkFrameView;

@interface PopMenuView : UIView {
	UIView *frameview; /* The menu itself, and the shadow behind it */
	UIView *content; /* The view inside the menu frame */
	UIView *decor; /* A nib at the bottom of the frameview (for the mini-tab bar) */
	UIView *faderview; /* A grey translucent overlay, used for dark color themes */
	UIEdgeInsets framemargins; /* The distance around the content view on all sides */
	CGRect buttonrect; /* The bounds of the button that launched this menu */
	int vertalign; /* 1: below the buttonrect; -1: above it; 0: centered */
	int horizalign; /* 1: to the right of the buttonrect; -1: to the left; 0: centered */
}

@property (nonatomic, strong) IBOutlet UIView *frameview;
@property (nonatomic, strong) IBOutlet UIView *content;
@property (nonatomic, strong) IBOutlet UIView *decor;
@property (nonatomic, strong) IBOutlet UIView *faderview;
@property (nonatomic) UIEdgeInsets framemargins;
@property (nonatomic, readonly) CGRect buttonrect;
@property (nonatomic, readonly) int vertalign;
@property (nonatomic, readonly) int horizalign;

- (instancetype) initWithFrame:(CGRect)frame centerInFrame:(CGRect)rect;
- (instancetype) initWithFrame:(CGRect)frame buttonFrame:(CGRect)rect belowButton:(BOOL)below;
- (instancetype) initWithFrame:(CGRect)frame buttonFrame:(CGRect)rect vertAlign:(int)vertval horizAlign:(int)horval;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) GlkFrameView *superviewAsFrameView;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *bottomDecorNib;
- (void) loadContent;
- (void) resizeContentTo:(CGSize)size animated:(BOOL)animated;
- (void) willRemove;

@end
