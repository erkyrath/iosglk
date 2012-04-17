/* GlkAccessTypes.m: Classes for VoiceOver accessibility
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import "GlkAccessTypes.h"
#import "GlkUtilTypes.h"
#import "StyledTextView.h"
#import "GlkWinGridView.h"
#import "StyleSet.h"

@implementation GlkAccVisualLine

@synthesize line;

+ (GlkAccVisualLine *) buildForLine:(GlkVisualLine *)vln container:(StyledTextView *)container {
	GlkAccVisualLine *el = [[[GlkAccVisualLine alloc] initWithAccessibilityContainer:container] autorelease];
	el.line = vln;
	el.isAccessibilityElement = YES;
	el.accessibilityTraits = UIAccessibilityTraitStaticText;
	return el;
}

- (NSString *) accessibilityLabel {
	if (!line)
		return NSLocalizedString(@"label.missing-line", nil);
	NSString *res = line.concatLine;
	if (res.length == 0)
		return NSLocalizedString(@"label.blank-line", nil);
	return res;
}

- (CGRect) accessibilityFrame {
	StyledTextView *view = (StyledTextView *)self.accessibilityContainer;
	
	if (!line || !view)
		return CGRectZero;
	
	CGRect rect = view.bounds; // for the left and right limits
	rect.origin.y = line.ypos;
	rect.size.height = line.height;
	
	if (line.vlinenum == view.vlines.count-1 && view.inputholder) {
		// shorten the line to miss the text field
		rect.size.width = line.right - line.xstart;
	}
	
	// Convert the rect from StyledTextView coordinates to screen coordinates.
	return [view.window convertRect:[view convertRect:rect toView:nil] toWindow:nil];
}

@end


@implementation GlkAccStyledLine

@synthesize line;

+ (GlkAccStyledLine *) buildForLine:(GlkStyledLine *)vln container:(GlkWinGridView *)container {
	GlkAccStyledLine *el = [[[GlkAccStyledLine alloc] initWithAccessibilityContainer:container] autorelease];
	el.line = vln;
	el.isAccessibilityElement = YES;
	el.accessibilityTraits = UIAccessibilityTraitStaticText;
	return el;
}

- (NSString *) accessibilityLabel {
	if (!line)
		return NSLocalizedString(@"label.missing-line", nil);
	NSString *res = line.concatLine;
	if (res.length == 0)
		return NSLocalizedString(@"label.blank-line", nil);
	return res;
}

- (CGRect) accessibilityFrame {
	GlkWinGridView *view = (GlkWinGridView *)self.accessibilityContainer;
	
	if (!line || !view)
		return CGRectZero;

	CGSize charbox = view.styleset.charbox;
	
	CGRect rect = view.bounds; // for the left and right limits
	rect.origin.y = view.styleset.margins.top + line.index * charbox.height;
	rect.size.height = charbox.height;
	
	//### if view.inputholder exists, avoid overlapping it!
	
	// Convert the rect from GlkWinGridView coordinates to screen coordinates.
	return [view.window convertRect:[view convertRect:rect toView:nil] toWindow:nil];
}

@end
