/* GlkFrameView.h: Main view class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>

@class GlkLibrary;

@interface GlkFrameView : UIView {
	/* Maps tags (NSNumbers) to GlkWindowViews. (But pair windows are excluded.) */
	NSMutableDictionary *windowviews;
}

@property (nonatomic, retain) NSMutableDictionary *windowviews;

- (void) updateFromLibraryState:(GlkLibrary *)library;

@end
