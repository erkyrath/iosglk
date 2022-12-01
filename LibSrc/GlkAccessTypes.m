/* GlkAccessTypes.m: Classes for VoiceOver accessibility
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import "GlkAccessTypes.h"
#import "GlkUtilTypes.h"
#import "GlkWinGridView.h"
#import "StyleSet.h"
#import "GlkUtilities.h"

@implementation GlkAccVisualLine

/* Change ">" at the beginning of the line to the string "prompt:".
 
	### This is Inform-specific. Really, this should be a GlkLibDelegate method.
 */
+ (NSString *) lineForSpeaking:(NSString *)val {
	if ([val hasPrefix:@">"]) {
		NSString *prefix = NSLocalizedString(@"label.prompt-colon", nil);
		NSRange range;
		range.location = 0;
		range.length = 1;
		val = [val stringByReplacingCharactersInRange:range withString:prefix];
	}

	return val;
}

- (CGRect) accessibilityFrame {
//	StyledTextView *view = (StyledTextView *)self.accessibilityContainer;
//
//	if (!line || !view)
//		return CGRectZero;
//
//	CGRect rect = RectApplyingEdgeInsets(view.bounds, view.viewmargin); // for the left and right limits
//	rect.origin.y = line.ypos;
//	rect.size.height = line.height;
//
//	if (line.vlinenum == view.vlines.count-1 && view.inputholder) {
//		// shorten the line to miss the text field
//		rect.size.width = line.right - line.xstart;
//	}
//
//	// Convert the rect from StyledTextView coordinates to screen coordinates.
//	return [view.window convertRect:[view convertRect:rect toView:nil] toWindow:nil];
    return CGRectZero;
}

@end


@implementation GlkAccStyledLine

- (CGRect) accessibilityFrame {
	GlkWinGridView *view = (GlkWinGridView *)self.accessibilityContainer;
	
	if (!view)
		return CGRectZero;

	CGSize charbox = view.styleset.charbox;
	
	CGRect rect = RectApplyingEdgeInsets(view.bounds, view.viewmargin); // for the left and right limits
	rect.size.height = charbox.height;
	
	//### if view.inputholder exists, avoid overlapping it!
	
	// Convert the rect from GlkWinGridView coordinates to screen coordinates.
	return [view.window convertRect:[view convertRect:rect toView:nil] toWindow:nil];
}

@end
