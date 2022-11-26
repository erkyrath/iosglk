/* IosGlkViewController.m: Main view controller class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "IosGlkViewController.h"
#import "IosGlkAppDelegate.h"
#import "IosGlkSceneDelegate.h"
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
#import "GlkWinBufferView.h"

#define MAX_HISTORY_LENGTH (12)

@implementation IosGlkViewController

+ (IosGlkViewController *) singleton {
	return [IosGlkAppDelegate singleton].glkviewc;
}


- (void) didFinishLaunching {
	/* Subclasses may override this (but should be sure to call [super didFinishLaunching]) */

	self.commandhistory = [NSMutableArray arrayWithCapacity:MAX_HISTORY_LENGTH];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSArray *arr = [defaults arrayForKey:@"CommandHistory"];
	if (arr) {
		[_commandhistory addObjectsFromArray:arr];
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

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

    UIInterfaceOrientation orientation = UIInterfaceOrientationPortrait;

    UIWindow *firstWindow = UIApplication.sharedApplication.windows[0];
    if (firstWindow != nil) {
        UIWindowScene *windowScene = firstWindow.windowScene;
        if (windowScene != nil){
            orientation = windowScene.interfaceOrientation;
        }
    }
	if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		BOOL hidenavbar = (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight);
		[self.navigationController setNavigationBarHidden:hidenavbar animated:NO];
	}
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSDictionary *activityUserInfo = self.view.window.windowScene.userActivity.userInfo;
    // Restore state
    if (activityUserInfo) {
        NSDictionary *stateOfViews = activityUserInfo[@"GlkWindowViewStates"];
        if (stateOfViews) {
            _frameview.waitingToRestoreFromState = YES;
            BOOL success = [_frameview updateWithUIStates:stateOfViews];
            if (!success) {
                // This only seems to happen when running on Catalyst
                // Missing _windowviews in _frameview, retrying in .1 secs
                GlkFrameView __block *blockFrameView = _frameview;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
                    [blockFrameView updateWithUIStates:stateOfViews];
                    blockFrameView.waitingToRestoreFromState = NO;
                });
            }
        }
    }
    [self updateUserActivity:nil];
}

- (void) viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[_frameview removePopMenuAnimated:NO];
}

- (void) viewDidLoad {
	[super viewDidLoad];
	IosGlkAppDelegate *appdelegate = [IosGlkAppDelegate singleton];
	if (appdelegate.library)
		[_frameview requestLibraryState:appdelegate.glkapp];
}

//- (void)viewWillLayoutSubviews {
//    [_frameview preserveScrollPositions];
//}
//
//- (void)viewDidLayoutSubviews {
//    [_frameview restoreScrollPositions];
//}

- (void) viewWillTransitionToSize:(CGSize)size
        withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [_frameview preserveScrollPositions];
    _frameview.inOrientationAnimation = YES;
	if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		BOOL hidenavbar = (size.width > size.height);
        
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) { self.navigationController.navigationBarHidden = hidenavbar; }
                                     completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self.frameview restoreScrollPositions];
        } ];
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

/* Invoked in the UI thread, from the VM thread. See comment on [GlkFrameView updateFromLibraryState].
 */
- (void) updateFromLibraryState:(GlkLibraryState *)library {
    /* Remember whether any window has the input focus. */
    BOOL anyfocus = NO;
    for (GlkWindowView *winv in (_frameview.windowviews).allValues) {
        if (winv.inputfield && (winv.inputfield).isFirstResponder) {
            anyfocus = YES;
            break;
        }
    }

    _vmexited = library.vmexited;
    if (_frameview)
        [_frameview updateFromLibraryState:library];

    if (anyfocus) {
        GlkWindowView *winv = self.preferredInputWindow;
        if (winv && winv.inputfield && !(winv.inputfield).isFirstResponder) {
            [winv.inputfield becomeFirstResponder];
        }
    }
}

/* This tests whether the keyboard is visible *and obscuring the screen*. (If the iPad's floating keyboard is up, this returns NO.)
 */
- (BOOL) keyboardIsShown {
    return (!CGRectIsEmpty(_keyboardbox));
}

- (void) keyboardWillBeShown:(NSNotification*)notification {
    NSDictionary *info = notification.userInfo;
    CGRect rect = CGRectZero;
    UIWindow *window = UIApplication.sharedApplication.windows[0];
    rect = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    rect = [window convertRect:rect fromWindow:nil];
    //NSLog(@"Keyboard will be shown, box %@ (window coords)", StringFromRect(rect));

    /* This rect is in window coordinates. */
    _keyboardbox = rect;

    if (_frameview)
        [_frameview setNeedsLayout];
}

- (void) keyboardWillBeHidden:(NSNotification*)notification {
    //NSLog(@"Keyboard will be hidden");
    _keyboardbox = CGRectZero;

    if (_frameview)
        [_frameview setNeedsLayout];
}

/* Return whether the system is set to dark mode. The app uses this to decide some minor display details, like scroll bar tint.
 */
- (BOOL) hasDarkTheme {
    return (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
}

- (void) preferInputWindow:(NSNumber *)tag {
    self.prefinputwintag = tag;
}

/* This returns (in order of preference) the window which currently has the input focus; the inputting window which last had the input focus; any inputting window. If no window is waiting for input at all, return nil.
 */
- (GlkWindowView *) preferredInputWindow {
    if (_vmexited)
        return nil;

    GlkWindowView *prefinputview = nil;
    GlkWindowView *firstinputview = nil;
    NSMutableDictionary *windowviews = _frameview.windowviews;

    for (NSNumber *tag in windowviews) {
        GlkWindowView *winv = windowviews[tag];
        if (winv.inputfield && (winv.inputfield).isFirstResponder) {
            return winv;
        }

        if (winv.inputfield) {
            if (!firstinputview)
                firstinputview = winv;
            if (NumberMatch(tag, _prefinputwintag))
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
    for (GlkWindowView *winv in (_frameview.windowviews).allValues) {
        if (winv.inputfield && (winv.inputfield).isFirstResponder) {
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

    if (winv.inputfield.isFirstResponder) {
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
    if (![GlkAppWrapper singleton].acceptingEvent) {
        /* The VM is not currently awaiting input. */
        return NO;
    }

    for (NSNumber *tag in _frameview.windowviews) {
        GlkWindowView *winv = (_frameview.windowviews)[tag];
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
    if (![GlkAppWrapper singleton].acceptingEvent) {
        /* The VM is not currently awaiting input. */
        return NO;
    }

    GlkEventState *event = [[GlkEventState alloc] init];
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
    CGRect rect = _frameview.bounds;
    GameOverView *menuview = [[GameOverView alloc] initWithFrame:_frameview.bounds centerInFrame:rect];
    [_frameview postPopMenu:menuview];
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

        NSString *sbname;
        if (prompt.fmode == filemode_Read)
            sbname = @"GlkFileSelectLoad";
        else
            sbname = @"GlkFileSelectStore";

        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"GlkFileSelect" bundle:nil];

        UINavigationController *navc = [sb instantiateViewControllerWithIdentifier:sbname];
        GlkFileSelectViewController *viewc = (GlkFileSelectViewController *)navc.viewControllers[0];
        viewc.prompt = prompt;
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

    [_commandhistory removeObject:str];
    [_commandhistory addObject:str];
    if (_commandhistory.count > MAX_HISTORY_LENGTH) {
        NSRange range;
        range.location = 0;
        range.length = _commandhistory.count - MAX_HISTORY_LENGTH;
        [_commandhistory removeObjectsInRange:range];
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_commandhistory forKey:@"CommandHistory"];
}

/* Display an alert sheet that doesn't come from the game. For example, this might be called when a file is passed to the app from another app.
 */
- (void) displayAdHocAlert:(NSString *)msg title:(NSString *)title {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"button.ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}]];

    UIPopoverPresentationController *popoverController = alert.popoverPresentationController;
    if (popoverController) {
        popoverController.sourceView = self.view;
        popoverController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 0, 0);
        popoverController.permittedArrowDirections = 0;
    }

    // Present alert sheet.
    [self presentViewController:alert animated:YES completion:nil];
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

    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:msg message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    IosGlkViewController __weak *weakSelf = self;

    [sheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"button.cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        questioncallback qcallback = weakSelf.currentquestion;
        weakSelf.currentquestion = nil;
        qcallback(0);
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:opt1 style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        questioncallback qcallback = weakSelf.currentquestion;
        weakSelf.currentquestion = nil;
        qcallback(1);
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:opt2 style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        questioncallback qcallback = weakSelf.currentquestion;
        weakSelf.currentquestion = nil;
        qcallback(2);
    }]];

    UIPopoverPresentationController *popoverController = sheet.popoverPresentationController;
    if (popoverController) {
        popoverController.sourceView = self.view;
        popoverController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 0, 0);
        popoverController.permittedArrowDirections = 0;
    }

    [self presentViewController:sheet animated:YES completion:nil];

}

- (void)textTapped:(UITapGestureRecognizer *)recognizer
{
    GlkWindowView *winv = [self preferredInputWindow];

    /* If there is no input line (anywhere), ignore single-tap and double-tap. (Unless the game is over, in which case we post that dialog.) */
    if (!winv || !winv.inputfield) {
        NSLog(@"no input line (anywhere)");
        if (_vmexited)
            [self postGameOver];
        return;
    }

    /* If there is a visible "more" indicator, all taps page down */
    if ([winv isKindOfClass:[GlkWinBufferView class]]) {
        GlkWinBufferView *bufview = (GlkWinBufferView *)winv;
        if (bufview.moreview.hidden == NO) {
            [bufview pageDownOnInput];
            return;
        }
    }

    UITextView *textView = (UITextView *)recognizer.view;
    NSRange selected = textView.selectedRange;
    if (selected.length) {
        textView.selectedRange = NSMakeRange(0, 0);
        if (![winv.inputfield isFirstResponder]) {
            [winv.inputfield becomeFirstResponder];
            return;
        }
    }

    /* Otherwise, single-tap focuses the input line or sends tapped word to input line */
    if (![winv.inputfield isFirstResponder]) {
        [winv.inputfield becomeFirstResponder];
    } else if (!winv.inputfield.singleChar) {
        NSLayoutManager *layoutManager = textView.layoutManager;
        CGPoint location = [recognizer locationInView:textView];
        location.x -= textView.textContainerInset.left;
        location.y -= textView.textContainerInset.top;

        NSUInteger
        characterIndex = [layoutManager characterIndexForPoint:location
                                               inTextContainer:textView.textContainer
                      fractionOfDistanceBetweenInsertionPoints:NULL];

        if (characterIndex < textView.textStorage.length) {
            CGRect rect;
            NSRange range;
            NSAttributedString *wd = attributedWordAtIndex(characterIndex, textView.textStorage, &range);
            if (wd) {
                /* Send an animated label flying downhill */
                UITextPosition *start = [textView positionFromPosition:textView.beginningOfDocument offset:range.location];
                UITextPosition *end = [textView positionFromPosition:start offset:range.length];
                UITextRange *textRange = [textView textRangeFromPosition:start toPosition:end];
                rect = [textView firstRectForRange:textRange];
                rect = [textView convertRect:rect toView:textView.superview];
                rect = CGRectInset(rect, -4, -2);
                UILabel *label = [[UILabel alloc] initWithFrame:rect];
                label.attributedText = wd;
                label.textAlignment = NSTextAlignmentCenter;
                label.backgroundColor = nil;
                label.opaque = NO;
                [textView.superview addSubview:label];
                CGPoint newpt = RectCenter(winv.inputholder.frame);
                CGSize curinputsize = [winv.inputfield.text sizeWithAttributes:@{NSFontAttributeName:winv.inputfield.font}];
                newpt.x = winv.inputholder.frame.origin.x + curinputsize.width + 0.5 * rect.size.width;
                newpt = [winv.inputholder.superview convertPoint:newpt toView:textView.superview];
                [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                    label.center = newpt;
                    label.alpha = 0.25;
                } completion:^(BOOL finished) {
                    [label removeFromSuperview];
                    /* Put the word into the input field */
                    [winv.inputfield applyInputString:wd.string replace:NO];
                }];
            }
        }
    }
}

- (NSUserActivity *)updateUserActivity:(nullable id)sender {

    /** Update the user activity for this view controller's scene.
     viewDidAppear calls this upon initial presentation. The IosGlkSceneDelegate stateRestorationActivityForScene also calls it.
     */

    NSUserActivity *currentUserActivity = self.view.window.windowScene.userActivity;
    if (currentUserActivity == nil) {
        IosGlkSceneDelegate *sceneDelegate = (IosGlkSceneDelegate *)self.view.window.windowScene.delegate;
        if (sceneDelegate) {
            currentUserActivity = [[NSUserActivity alloc] initWithActivityType:[sceneDelegate mainSceneActivityType]];
        } else
            return nil;
    }

    [currentUserActivity addUserInfoEntriesFromDictionary:[_frameview getCurrentViewStates]];
    self.view.window.windowScene.userActivity = currentUserActivity;
    
    return currentUserActivity;
}

@end
