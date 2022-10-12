/* GlkAccessTypes.h: Classes for VoiceOver accessibility
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import <UIKit/UIKit.h>

@class GlkWinGridView;
@class StyledTextView;
@class GlkStyledLine;
@class GlkVisualLine;

@interface GlkAccVisualLine : UIAccessibilityElement {
	GlkVisualLine *__weak line; /* weak parent link -- unretained */
}

@property (nonatomic, weak) GlkVisualLine *line;

+ (NSString *) lineForSpeaking:(NSString *)val;
+ (GlkAccVisualLine *) buildForLine:(GlkVisualLine *)vln container:(StyledTextView *)container;

@end



@interface GlkAccStyledLine : UIAccessibilityElement {
	GlkStyledLine *__weak line; /* weak parent link -- unretained */
}

@property (nonatomic, weak) GlkStyledLine *line;

+ (GlkAccStyledLine *) buildForLine:(GlkStyledLine *)vln container:(GlkWinGridView *)container;

@end
