/* GlkFrameView.h: Main view class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>
#import "InputMenuView.h"

@class GlkLibrary;
@class GlkAppWrapper;
@class GlkWindowView;
@class GlkTagString;
@class PopMenuView;

@interface GlkFrameView : UIView {
	/* How much of the view bounds to reserve for the keyboard. */
	CGRect keyboardBox;
	/* The current size of the bounds minus keyboard. */
	CGRect cachedGlkBox;
	
	/* Maps tags (NSNumbers) to GlkWindowViews. (But pair windows are excluded.) */
	NSMutableDictionary *windowviews;
	/* Maps tags (NSNumbers) to Geometry objects. (Only for pair windows.) */
	NSMutableDictionary *wingeometries;
	NSNumber *rootwintag;
	
	/* Strings typed into input lines (across all windows) */
	NSMutableArray *commandhistory;

	PopMenuView *menuview;
	InputMenuMode inputmenumode;
}

@property (nonatomic, retain) NSMutableDictionary *windowviews;
@property (nonatomic, retain) NSMutableDictionary *wingeometries;
@property (nonatomic) CGRect keyboardBox;
@property (nonatomic, retain) NSNumber *rootwintag;
@property (nonatomic, retain) NSMutableArray *commandhistory;
@property (nonatomic, retain) PopMenuView *menuview;

- (GlkWindowView *) windowViewForTag:(NSNumber *)tag;
- (void) requestLibraryState:(GlkAppWrapper *)glkapp;
- (void) updateFromLibraryState:(GlkLibrary *)library;
- (void) updateWindowStyles;
- (void) windowViewRearrange:(NSNumber *)tag rect:(CGRect)box;
- (void) editingTextForWindow:(GlkTagString *)tagstring;
- (void) addToCommandHistory:(NSString *)str;
- (void) postPopMenu:(PopMenuView *)menuview;
- (void) removePopMenuAnimated:(BOOL)animated;

@end


