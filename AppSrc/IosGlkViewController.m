/* IosGlkViewController.m: Main view controller class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "IosGlkViewController.h"
#import "IosGlkAppDelegate.h"
#import "GlkAppWrapper.h"
#import "GlkFrameView.h"
#import "GlkWindowView.h"
#import "GlkUtilTypes.h"
#import "GlkFileTypes.h"
#import "GlkFileSelectViewController.h"
#import "MoreBoxView.h"
#import "PopMenuView.h"
#import "GameOverView.h"
#import "GlkLibraryState.h"
#import "GlkWindowState.h"
#import "CmdTextField.h"
#import "GlkUtilities.h"

#define MAX_HISTORY_LENGTH (12)

@implementation IosGlkViewController

@synthesize glkdelegate;
@synthesize frameview;
@synthesize vmexited;
@synthesize prefinputwintag;
@synthesize textselecttag;
@synthesize commandhistory;
@synthesize keyboardbox;
@synthesize currentquestion;

+ (IosGlkViewController *) singleton {
	return [IosGlkAppDelegate singleton].glkviewc;
}

- (void) dealloc {
	self.frameview = nil;
	self.commandhistory = nil;
	self.prefinputwintag = nil;
	self.textselecttag = nil;
	self.currentquestion = nil;
	[super dealloc];
}

- (void) didFinishLaunching {
	/* Subclasses may override this (but should be sure to call [super didFinishLaunching]) */

	self.commandhistory = [NSMutableArray arrayWithCapacity:MAX_HISTORY_LENGTH];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSArray *arr = [defaults arrayForKey:@"CommandHistory"];
	if (arr) {
		[commandhistory addObjectsFromArray:arr];
	}
}

- (void) becameInactive {
	/* Subclasses may override this */
}

- (void) becameActive {
	/* Subclasses may override this */
}

- (void) enteredBackground {
	/* Subclasses may override this */
}

- (void) viewDidUnload {
	[super viewDidUnload];
	self.frameview = nil;
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		BOOL hidenavbar = (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight);
		[self.navigationController setNavigationBarHidden:hidenavbar animated:NO];
	}
}

- (void) viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[frameview removePopMenuAnimated:NO];
}

- (void) viewDidLoad {
	[super viewDidLoad];
	IosGlkAppDelegate *appdelegate = [IosGlkAppDelegate singleton];
	if (appdelegate.library)
		[frameview requestLibraryState:appdelegate.glkapp];
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		BOOL hidenavbar = (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight);
		[self.navigationController setNavigationBarHidden:hidenavbar animated:YES];
	}
}

/* Allow all orientations. (An interpreter-specific subclass may override this.) iOS6+ idiom.
 */
- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAll;
}

/* Invoked in the UI thread when an event is generated. The view controller has a chance to intercept the event and do something with or to it. Return nil to block the event; return the argument unchanged to do nothing.
 */
- (id) filterEvent:(id)data {
	return data;
}

/* Invoked in the UI thread, from the VM thread. See comment on GlkFrameView.updateFromLibraryState.
 */
- (void) updateFromLibraryState:(GlkLibraryState *)library {
	/* Remember whether any window has the input focus. */
	BOOL anyfocus = NO;
	for (GlkWindowView *winv in [frameview.windowviews allValues]) {
		if (winv.inputfield && [winv.inputfield isFirstResponder]) {
			anyfocus = YES;
			break;
		}
	}
	
	vmexited = library.vmexited;
	if (frameview)
		[frameview updateFromLibraryState:library];
	
	if (anyfocus) {
		GlkWindowView *winv = self.preferredInputWindow;
		if (winv && winv.inputfield && ![winv.inputfield isFirstResponder]) {
			[winv.inputfield becomeFirstResponder];
		}
	}
}

/* This tests whether the keyboard is visible *and obscuring the screen*. (If the iPad's floating keyboard is up, this returns NO.)
 */
- (BOOL) keyboardIsShown {
	return (!CGRectIsEmpty(keyboardbox));
}

- (void) keyboardWillBeShown:(NSNotification*)notification {
	NSDictionary *info = [notification userInfo];
	CGRect rect = CGRectZero;
	UIWindow *window = [IosGlkAppDelegate singleton].window;
	rect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	rect = [window convertRect:rect fromWindow:nil];
	//NSLog(@"Keyboard will be shown, box %@ (window coords)", StringFromRect(rect));
	
	/* This rect is in window coordinates. */
	keyboardbox = rect;
	
	if (frameview)
		[frameview setNeedsLayout];
}

- (void) keyboardWillBeHidden:(NSNotification*)notification {
	//NSLog(@"Keyboard will be hidden");
	keyboardbox = CGRectZero;
	
	if (frameview)
		[frameview setNeedsLayout];
}

- (void) textSelectionWindow:(NSNumber *)tag {
	self.textselecttag = tag;
}

- (void) preferInputWindow:(NSNumber *)tag {
	self.prefinputwintag = tag;
}

/* This returns (in order of preference) the window which currently has the input focus; the inputting window which last had the input focus; any inputting window. If no window is waiting for input at all, return nil.
 */
- (GlkWindowView *) preferredInputWindow {
	if (vmexited)
		return nil;
	
	GlkWindowView *prefinputview = nil;
	GlkWindowView *firstinputview = nil;
	NSMutableDictionary *windowviews = frameview.windowviews;
	
	for (NSNumber *tag in windowviews) {
		GlkWindowView *winv = [windowviews objectForKey:tag];
		if (winv.inputfield && [winv.inputfield isFirstResponder]) {
			return winv;
		}
		
		if (winv.inputfield) {
			if (!firstinputview)
				firstinputview = winv;
			if (NumberMatch(tag, prefinputwintag))
				prefinputview = winv;
		}
	}
	
	if (prefinputview)
		return prefinputview;
	else if (firstinputview)
		return firstinputview;
	else
		return nil;
}

- (void) hideKeyboard {
	for (GlkWindowView *winv in [frameview.windowviews allValues]) {
		if (winv.inputfield && [winv.inputfield isFirstResponder]) {
			//NSLog(@"Hiding keyboard for %@", winv);
			[winv.inputfield resignFirstResponder];
			break;
		}
	}
}

- (IBAction) toggleKeyboard {
	GlkWindowView *winv = self.preferredInputWindow;
	if (!winv || !winv.inputfield)
		return;
	
	if ([winv.inputfield isFirstResponder]) {
		//NSLog(@"Hiding keyboard for %@", winv);
		[winv.inputfield resignFirstResponder];
	}
	else {
		//NSLog(@"Reshowing keyboard for %@", firstinputview);
		[winv.inputfield becomeFirstResponder];
	}
}

/* Update the input field, as if the player had typed the string. (Any input the player was editing is replaced.) If enter is YES, a line input event is generated, as if the player had then hit Go.
 
	If no windows are accepting line input, nothing happens (and the method returns NO). If a window is, it succeeds and returns YES. (If more than one is, it picks one.)
 
	This is intended to be called by UI controls. For example, you might have a button in your app interface which generates an "INVENTORY" command.
 */
- (BOOL) forceLineInput:(NSString *)text enter:(BOOL)enter
{
	if (![[GlkAppWrapper singleton] acceptingEvent]) {
		/* The VM is not currently awaiting input. */
		return NO;
	}
	
	for (NSNumber *tag in frameview.windowviews) {
		GlkWindowView *winv = [frameview.windowviews objectForKey:tag];
		if (winv.inputfield && winv.winstate.line_request) {
			if (!enter) {
				winv.inputfield.text = text;
			}
			else {
				// We can't absolutely guarantee that this will succeed -- the VM has to decide that. But we'll return YES anyhow.
				[[GlkAppWrapper singleton] acceptEvent:[GlkEventState lineEvent:text inWindow:winv.winstate.tag]];
			}
			return YES;
		}
	}
	
	return NO;
}

/* Send a custom event directly to the VM. Returns YES if the VM is in glk_select(); if not, does nothing and returns NO.
 
	The tag argument will be converted to a window ID in the event structure. If tag is nil, the window ID will be zero.
 */
- (BOOL) forceCustomEvent:(uint32_t)evtype windowTag:(NSNumber *)tag val1:(uint32_t)val1 val2:(uint32_t)val2
{
	if (![[GlkAppWrapper singleton] acceptingEvent]) {
		/* The VM is not currently awaiting input. */
		return NO;
	}
	
	GlkEventState *event = [[[GlkEventState alloc] init] autorelease];
	event.type = evtype;
	event.tag = tag;
	event.genval1 = val1;
	event.genval2 = val2;
	
	[[GlkAppWrapper singleton] acceptEvent:event];
	return YES;
}

/* Display the "game over, what now?" popup. This is called when the player taps after glk_main() has exited.
 */
- (void) postGameOver {
	CGRect rect = frameview.bounds;
	GameOverView *menuview = [[[GameOverView alloc] initWithFrame:frameview.bounds centerInFrame:rect] autorelease];
	[frameview postPopMenu:menuview];	
}

/* Display the appropriate modal pop-up when updating the display (at glk_select time, or whenever the VM blocks.) 
 
	Called from updateFromLibraryState. It can also be called after the game is over. (IosFizmo has a "Restore" button in the postGameOver dialog.)
 */
- (void) displayModalRequest:(id)special {
	if (!special) {
		/* Regular glk_select(); no modal view here. */
		return;
	}
	
	if ([special isKindOfClass:[NSNull class]]) {
		/* glk_exit(): no modal view here. (The game-over dialog is handled differently.) */
		return;
	}
	
	if ([special isKindOfClass:[GlkFileRefPrompt class]]) {
		/* File selection. */
		GlkFileRefPrompt *prompt = (GlkFileRefPrompt *)special;
		
		NSString *nibname;
		if (prompt.fmode == filemode_Read)
			nibname = @"GlkFileSelectLoad";
		else
			nibname = @"GlkFileSelectStore";
			
		GlkFileSelectViewController *viewc = [[[GlkFileSelectViewController alloc] initWithNibName:nibname prompt:prompt bundle:nil] autorelease];
		UINavigationController *navc = [[[UINavigationController alloc] initWithRootViewController:viewc] autorelease];
		[navc setModalPresentationStyle:UIModalPresentationFormSheet];
		/* Make the navbar opaque, so that iOS7 doesn't try to underlap the view behind it. Nobody likes that. */
		navc.navigationBar.translucent = NO;
		[self presentViewController:navc animated:YES completion:nil];
		return;
	}

	[NSException raise:@"GlkException" format:@"tried to raise unknown modal request"];
}

- (void) addToCommandHistory:(NSString *)str {
	NSArray *arr = [str componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (arr.count == 0)
		return;
	NSMutableArray *arr2 = [NSMutableArray arrayWithCapacity:arr.count];
	for (NSString *substr in arr) {
		if (substr.length)
			[arr2 addObject:substr];
	}
	if (!arr2.count)
		return;
	str = [arr2 componentsJoinedByString:@" "];
	//str = str.lowercaseString;
	
	// for this test, should really measure the string's length excluding closing punctuation and spaces
	if (str.length <= 2)
		return;
	
	[commandhistory removeObject:str];
	[commandhistory addObject:str];
	if (commandhistory.count > MAX_HISTORY_LENGTH) {
		NSRange range;
		range.location = 0;
		range.length = commandhistory.count - MAX_HISTORY_LENGTH;
		[commandhistory removeObjectsInRange:range];
	}
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:commandhistory forKey:@"CommandHistory"];
}

/* Display an alert sheet that doesn't come from the game. For example, this might be called when a file is passed to the app from another app.
 */
- (void) displayAdHocAlert:(NSString *)msg title:(NSString *)title {
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:NSLocalizedString(@"button.ok", nil) otherButtonTitles:nil] autorelease];
	[alert show];
}

/* Display an action sheet to ask a two-option question. (There's always a "cancel" option. This does not use the "destructive" red-button option.)
 The callback will be invoked with argument 1 or 2, or 0 for cancel.
 If there's already a question sheet visible, this fails and auto-cancels. (Weak, I know, sorry.)
 */
- (void) displayAdHocQuestion:(NSString *)msg option:(NSString *)opt1 option:(NSString *)opt2 callback:(questioncallback)qcallback {
	if (self.currentquestion) {
		NSLog(@"displayAdHocQuestion: current question already exists; cancelling");
		qcallback(0);
		return;
	}
	self.currentquestion = qcallback;
	UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:msg delegate:self cancelButtonTitle:NSLocalizedString(@"button.cancel", nil) destructiveButtonTitle:nil otherButtonTitles:opt1, opt2, nil] autorelease];
	sheet.delegate = self;
	[sheet showInView:[IosGlkAppDelegate singleton].rootviewc.view];
}

/* Delegate method for UIActionSheet. Used by displayAdHocQuestion.
 */
- (void) actionSheet:(UIActionSheet *)sheet didDismissWithButtonIndex:(NSInteger)index {
	int res;
	if (index == -1 || index == sheet.cancelButtonIndex)
		res = 0;
	else
		res = (index - sheet.firstOtherButtonIndex) + 1;
	
	questioncallback qcallback = [[self.currentquestion retain] autorelease];
	self.currentquestion = nil;
	qcallback(res);
}

- (void) didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

@end
