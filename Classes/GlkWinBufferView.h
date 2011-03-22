/* GlkWinBufferView.h: Glk textbuffer window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>
#import "GlkWindowView.h"

@class StyledTextView;

@interface GlkWinBufferView : GlkWindowView <UIScrollViewDelegate> {
	UIScrollView *scrollview;
	StyledTextView *textview;
	
	CGRect lastLayoutBounds;
}

@property (nonatomic, retain) UIScrollView *scrollview;
@property (nonatomic, retain) StyledTextView *textview;

@end
