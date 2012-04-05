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
	BOOL belowbutton; /* Does this hang below the buttonrect? */
}

@property (nonatomic, retain) IBOutlet UIView *frameview;
@property (nonatomic, retain) IBOutlet UIView *content;
@property (nonatomic, retain) IBOutlet UIView *decor;
@property (nonatomic, retain) IBOutlet UIView *faderview;
@property (nonatomic) UIEdgeInsets framemargins;
@property (nonatomic, readonly) CGRect buttonrect;
@property (nonatomic, readonly) BOOL belowbutton;

- (id) initWithFrame:(CGRect)frame buttonFrame:(CGRect)rect belowButton:(BOOL)below;
- (GlkFrameView *) superviewAsFrameView;
- (NSString *) bottomDecorNib;
- (void) loadContent;
- (void) resizeContentTo:(CGSize)size animated:(BOOL)animated;

@end
