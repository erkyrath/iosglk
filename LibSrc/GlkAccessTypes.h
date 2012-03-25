/* GlkAccessTypes.h: Classes for VoiceOver accessibility
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import <UIKit/UIKit.h>

@class StyledTextView;
@class GlkVisualLine;

@interface GlkAccVisualLine : UIAccessibilityElement {
	GlkVisualLine *line; /* weak parent link -- unretained */
}

@property (nonatomic, assign) GlkVisualLine *line;

+ (GlkAccVisualLine *) buildForLine:(GlkVisualLine *)vln container:(StyledTextView *)container;

@end
