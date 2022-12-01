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

typedef void (^questioncallback)(int); // callback block type for displayAdHocQuestion

@interface IosGlkViewController : UIViewController <UIActionSheetDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, weak) IBOutlet id <IosGlkLibDelegate> glkdelegate; // delegates are nonretained
@property (nonatomic, strong) IBOutlet GlkFrameView *frameview;

/* Tag for the window which most recently had input focus */
@property (nonatomic, strong) NSNumber *prefinputwintag;
/* As of the most recent update */
@property (nonatomic) BOOL vmexited;

/* Strings typed into input lines (across all windows) */
@property (nonatomic, strong) NSMutableArray *commandhistory;
/* Size of the keyboard, if present *and blocking* (in window coords) */
@property (nonatomic) CGRect keyboardbox;

/* Currently-displayed ad-hoc question callback */
@property (nonatomic, copy) questioncallback currentquestion;

+ (IosGlkViewController *) singleton;

- (void) didFinishLaunching;
- (void) becameInactive;
- (void) becameActive;
- (void) enteredBackground;
- (void) updateFromLibraryState:(GlkLibraryState *)library;
- (id) filterEvent:(id)data;

- (void) preferInputWindow:(NSNumber *)tag;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) GlkWindowView *preferredInputWindow;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL keyboardIsShown;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasDarkTheme;
- (void) hideKeyboard;
- (void) postGameOver;
- (void) displayModalRequest:(id)special;
- (void) keyboardWillBeShown:(NSNotification*)notification;
- (void) keyboardWillBeHidden:(NSNotification*)notification;

- (IBAction) toggleKeyboard;
- (BOOL) forceLineInput:(NSString *)text enter:(BOOL)enter;
- (BOOL) forceCustomEvent:(uint32_t)evtype windowTag:(NSNumber *)tag val1:(uint32_t)val1 val2:(uint32_t)val2;
- (void) addToCommandHistory:(NSString *)str;
- (void) displayAdHocAlert:(NSString *)msg title:(NSString *)title;
- (void) displayAdHocQuestion:(NSString *)msg option:(NSString *)opt1 option:(NSString *)opt2 callback:(questioncallback)qcallback;
- (void)textTapped:(UITapGestureRecognizer *)recognizer;
- (NSUserActivity *)updateUserActivity:(id)sender;

@end

