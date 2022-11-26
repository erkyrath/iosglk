/* GlkFrameView.h: Main view class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>
#import "InputMenuView.h"

@class GlkLibraryState;
@class GlkAppWrapper;
@class GlkWindowView;
@class GlkTagString;
@class PopMenuView;
@class Geometry;

@interface GlkFrameView : UIView {	
	/* The current size of the bounds minus keyboard. */
	CGRect cachedGlkBox;
	/* True if we should re-layout even when the box hasn't changed. */
	BOOL cachedGlkBoxInvalid;

	InputMenuMode inputmenumode;
}

/* A clone of the library's state, as of the last updateFromLibraryState call. */
@property (nonatomic, strong) GlkLibraryState *librarystate;
/* Maps tags (NSNumbers) to GlkWindowViews. (But pair windows are excluded.) */
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, GlkWindowView *> *windowviews;

/* Maps tags (NSNumbers) to Geometry objects. (Only for pair windows.) */
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, Geometry *> *wingeometries;
@property (nonatomic, strong) NSNumber *rootwintag;
@property (nonatomic, strong) PopMenuView *menuview;
@property (nonatomic) BOOL inOrientationAnimation;
@property (nonatomic) BOOL waitingToRestoreFromState;

- (GlkWindowView *) windowViewForTag:(NSNumber *)tag;
- (void) requestLibraryState:(GlkAppWrapper *)glkapp;
- (void) updateFromLibraryState:(GlkLibraryState *)library;
- (void) updateWindowStyles;
- (void) updateInputTraits;
- (void) windowViewRearrange:(NSNumber *)tag rect:(CGRect)box;
- (void) editingTextForWindow:(GlkTagString *)tagstring;
- (void) postPopMenu:(PopMenuView *)menuview;
- (void) removePopMenuAnimated:(BOOL)animated;
- (NSDictionary *)getCurrentViewStates;
- (BOOL) updateWithUIStates:(NSDictionary *)states;
- (void) preserveScrollPositions;
- (void) restoreScrollPositions;
- (BOOL) hasStandardGlkSetup;

@end


