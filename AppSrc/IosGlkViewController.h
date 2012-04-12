/* IosGlkViewController.h: Main view controller class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>

@class GlkFrameView;
@class GlkWindowView;
@class PopMenuView;
@class MoreBoxView;
@class GlkLibraryState;
@protocol IosGlkLibDelegate;

@interface IosGlkViewController : UIViewController {
	id <IosGlkLibDelegate> glkdelegate;
	GlkFrameView *frameview;
	
	/* Tag for the window which most recently had input focus */
	NSNumber *prefinputwintag;

	/* Strings typed into input lines (across all windows) */
	NSMutableArray *commandhistory;	
}

@property (nonatomic, assign) IBOutlet id <IosGlkLibDelegate> glkdelegate; // delegates are nonretained
@property (nonatomic, retain) IBOutlet GlkFrameView *frameview;

@property (nonatomic, retain) NSNumber *prefinputwintag;

@property (nonatomic, retain) NSMutableArray *commandhistory;	
@property (nonatomic) CGRect keyboardbox;

+ (IosGlkViewController *) singleton;

- (void) didFinishLaunching;
- (void) becameInactive;
- (void) becameActive;
- (void) enteredBackground;
- (void) updateFromLibraryState:(GlkLibraryState *)library;

- (void) preferInputWindow:(NSNumber *)tag;
- (GlkWindowView *) preferredInputWindow;
- (void) hideKeyboard;
- (void) displayModalRequest:(id)special;
- (void) keyboardWillBeShown:(NSNotification*)notification;
- (void) keyboardWillBeHidden:(NSNotification*)notification;

- (IBAction) toggleKeyboard;
- (void) addToCommandHistory:(NSString *)str;

@end

