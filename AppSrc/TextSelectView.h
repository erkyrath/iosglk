/* TextSelectView.h: View for a text-selection overlap
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import <UIKit/UIKit.h>

@interface TextSelectView : UIView {
	UIView *shadeview;
	UIView *outlineview;
	
	CGRect area;
}

@property (nonatomic, retain) UIView *shadeview;
@property (nonatomic, retain) UIView *outlineview;

- (void) setArea:(CGRect)box;

@end
