/* GlkAccessTypes.h: Classes for VoiceOver accessibility
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import <UIKit/UIKit.h>

@class GlkWinGridView;
@class StyledTextView;

@interface GlkAccVisualLine : UIAccessibilityElement


+ (NSString *) lineForSpeaking:(NSString *)val;

@end


@interface GlkAccStyledLine : UIAccessibilityElement

@end
