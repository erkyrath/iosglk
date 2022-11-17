/* GlkWinBufferView.h: Glk textbuffer window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>
#import "GlkWindowView.h"

@class StyledTextView;
@class MoreBoxView;

@interface GlkWinBufferView : GlkWindowView <UIScrollViewDelegate, UITextViewDelegate> {
	CGRect lastLayoutBounds;
    NSLayoutConstraint *textviewHeightConstraint;
    BOOL firstUpdate;
    NSUInteger recursionDepth;
    BOOL storedAtBottom;
    BOOL storedAtTop;
    NSUInteger lastVisibleGlyph;
    BOOL inAnimatedScrollToBottom;
}

@property (nonatomic, strong) UITextView *textview;
@property (nonatomic, strong) MoreBoxView *moreview;
@property (nonatomic) BOOL nowcontentscrolling;
@property (nonatomic) NSUInteger clearcount;
@property (nonatomic) NSUInteger lastSeenCharacterIndex;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL pageDownOnInput;

- (BOOL) scrolledToBottom;
- (void) scrollTextViewToBottomAnimate:(BOOL)animate;
- (void) preserveScrollPosition;
- (void) restoreScrollPosition;

@end
