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

@interface IosGlkViewController : UIViewController <UIActionSheetDelegate> {
	id <IosGlkLibDelegate> __weak glkdelegate;
	GlkFrameView *frameview;
	
	/* Tag for the window which most recently had input focus */
	NSNumber *prefinputwintag;
	/* Tag for the window which currently has text selected */
	NSNumber *textselecttag;
	/* As of the most recent update */
	BOOL vmexited;

	/* Strings typed into input lines (across all windows) */
	NSMutableArray *commandhistory;
	/* Size of the keyboard, if present *and blocking* (in window coords) */
	CGRect keyboardbox;
	
	/* Currently-displayed ad-hoc question callback */
	questioncallback currentquestion;
}

@property (nonatomic, weak) IBOutlet id <IosGlkLibDelegate> glkdelegate; // delegates are nonretained
@property (nonatomic, strong) IBOutlet GlkFrameView *frameview;

@property (nonatomic, strong) NSNumber *prefinputwintag;
@property (nonatomic, strong) NSNumber *textselecttag;
@property (nonatomic) BOOL vmexited;

@property (nonatomic, strong) NSMutableArray *commandhistory;	
@property (nonatomic) CGRect keyboardbox;

@property (nonatomic, copy) questioncallback currentquestion;

+ (IosGlkViewController *) singleton;

- (void) didFinishLaunching;
- (void) becameInactive;
- (void) becameActive;
- (void) enteredBackground;
- (void) updateFromLibraryState:(GlkLibraryState *)library;
- (id) filterEvent:(id)data;

- (void) textSelectionWindow:(NSNumber *)tag;
- (void) preferInputWindow:(NSNumber *)tag;
- (GlkWindowView *) preferredInputWindow;
- (BOOL) keyboardIsShown;
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

@end

