/* TextSelectView.h: View for a text-selection overlap
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import <UIKit/UIKit.h>

#define HANDLE_RADIUS (25)

@interface TextSelectView : UIView {
	UIView *shadeview;
	UIView *outlineview;
	UIImageView *tophandleview;
	UIImageView *bottomhandleview;
	
	CGRect area;
	CGRect outline;
	BOOL outlinevisible;
}

@property (nonatomic, retain) UIView *shadeview;
@property (nonatomic, retain) UIView *outlineview;
@property (nonatomic, retain) UIImageView *tophandleview;
@property (nonatomic, retain) UIImageView *bottomhandleview;

- (void) setArea:(CGRect)box;
- (void) setOutline:(CGRect)box animated:(BOOL)animated;
- (void) hideOutlineAnimated:(BOOL)animated;

@end


@interface TextOutlineView : UIView {
}

@end
