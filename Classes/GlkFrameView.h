/* GlkFrameView.h: Main view class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>

@class GlkLibrary;
@class GlkTagString;

@interface GlkFrameView : UIView {
	/* How much of the view bounds to reserve for the keyboard. */
	CGFloat keyboardHeight;
	
	/* Maps tags (NSNumbers) to GlkWindowViews. (But pair windows are excluded.) */
	NSMutableDictionary *windowviews;
	/* Maps tags (NSNumbers) to Geometry objects. (Only for pair windows.) */
	NSMutableDictionary *wingeometries;
	NSNumber *rootwintag;
}

@property (nonatomic, retain) NSMutableDictionary *windowviews;
@property (nonatomic, retain) NSMutableDictionary *wingeometries;
@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic, retain) NSNumber *rootwintag;

- (void) updateFromLibraryState:(GlkLibrary *)library;
- (void) windowViewRearrange:(NSNumber *)tag rect:(CGRect)box;
//###- (void) updateFromLibrarySize:(GlkLibrary *)library;
- (void) editingTextForWindow:(GlkTagString *)tagstring;

@end
