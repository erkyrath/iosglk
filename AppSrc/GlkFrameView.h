/* GlkFrameView.h: Main view class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>
#import "InputMenuView.h"

@class GlkLibrary;
@class GlkTagString;
@class InputMenuView;

@interface GlkFrameView : UIView {
	/* How much of the view bounds to reserve for the keyboard. */
	CGFloat keyboardHeight;
	/* The current size of the bounds minus keyboard. */
	CGRect cachedGlkBox;
	
	/* Maps tags (NSNumbers) to GlkWindowViews. (But pair windows are excluded.) */
	NSMutableDictionary *windowviews;
	/* Maps tags (NSNumbers) to Geometry objects. (Only for pair windows.) */
	NSMutableDictionary *wingeometries;
	NSNumber *rootwintag;
	
	/* Strings typed into input lines (across all windows) */
	NSMutableArray *commandhistory;

	InputMenuView *menuview;
	InputMenuMode inputmenumode;
	/* The window whose text field the popup menu applies to */
	NSNumber *menuwintag;
}

@property (nonatomic, retain) NSMutableDictionary *windowviews;
@property (nonatomic, retain) NSMutableDictionary *wingeometries;
@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic, retain) NSNumber *rootwintag;
@property (nonatomic, retain) NSMutableArray *commandhistory;
@property (nonatomic, retain) UIView *menuview;
@property (nonatomic, retain) NSNumber *menuwintag;

- (void) setNeedsLayoutPlusSubviews;
- (void) updateFromLibraryState:(GlkLibrary *)library;
- (void) windowViewRearrange:(NSNumber *)tag rect:(CGRect)box;
- (void) editingTextForWindow:(GlkTagString *)tagstring;
- (void) addToCommandHistory:(NSString *)str;
- (void) postInputMenuForWindow:(NSNumber *)tag;
- (void) removeInputMenu;
- (void) setInputMenuMode:(InputMenuMode)mode;
- (void) applyInputString:(NSString *)cmd replace:(BOOL)replace;

@end


