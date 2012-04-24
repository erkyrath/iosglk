/* IosGlkViewController.m: Main view controller class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "IosGlkViewController.h"
#import "IosGlkAppDelegate.h"
#import "GlkFrameView.h"
#import "GlkWindowView.h"
#import "GlkUtilTypes.h"
#import "GlkFileTypes.h"
#import "GlkFileSelectViewController.h"
#import "MoreBoxView.h"
#import "PopMenuView.h"
#import "GameOverView.h"
#import "GlkLibraryState.h"
#import "GlkUtilities.h"

#define MAX_HISTORY_LENGTH (12)

@implementation IosGlkViewController

@synthesize glkdelegate;
@synthesize frameview;
@synthesize vmexited;
@synthesize prefinputwintag;
@synthesize commandhistory;
@synthesize keyboardbox;

+ (IosGlkViewController *) singleton {
	return [IosGlkAppDelegate singleton].glkviewc;
}

- (void) dealloc {
	NSLog(@"IosGlkViewController dealloc %x", (unsigned int)self);
	self.frameview = nil;
	self.commandhistory = nil;
	self.prefinputwintag = nil;
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
	NSLog(@"viewDidUnload");
	self.frameview = nil;
}

- (void) viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[frameview removePopMenuAnimated:NO];
}

- (void) viewDidLoad {
	IosGlkAppDelegate *appdelegate = [IosGlkAppDelegate singleton];
	NSLog(@"viewDidLoad (library is %x)", (unsigned int)(appdelegate.library));
	if (appdelegate.library)
		[frameview requestLibraryState:appdelegate.glkapp];
}

/* Invoked in the UI thread, from the VM thread, which will block until this returns. See comment on GlkFrameView.updateFromLibraryState.
 */
- (void) updateFromLibraryState:(GlkLibraryState *)library {
	vmexited = library.vmexited;
	if (frameview)
		[frameview updateFromLibraryState:library];
}

- (void) keyboardWillBeShown:(NSNotification*)notification {
	NSDictionary *info = [notification userInfo];
	CGRect rect = CGRectZero;
	/* UIKeyboardFrameEndUserInfoKey is only available in iOS 3.2 or later. Note the funny idiom for testing the presence of a weak-linked symbol. */
	if (&UIKeyboardFrameEndUserInfoKey) {
		UIWindow *window = [IosGlkAppDelegate singleton].window;
		rect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
		rect = [window convertRect:rect fromWindow:nil];
	}
	else {
		/* iOS 3.1.3... */
		rect = [[info objectForKey:UIKeyboardBoundsUserInfoKey] CGRectValue];
		CGPoint center = [[info objectForKey:UIKeyboardCenterEndUserInfoKey] CGPointValue];
		rect.origin.x = center.x - 0.5*rect.size.width;
		rect.origin.y = center.y - 0.5*rect.size.height;
	}
	NSLog(@"Keyboard will be shown, box %@ (window coords)", StringFromRect(rect));
	
	/* This rect is in window coordinates. */
	keyboardbox = rect;
	
	if (frameview)
		[frameview setNeedsLayout];
}

- (void) keyboardWillBeHidden:(NSNotification*)notification {
	NSLog(@"Keyboard will be hidden");
	keyboardbox = CGRectZero;
	
	if (frameview)
		[frameview setNeedsLayout];
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

// Allow all orientations
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

/*
- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)prevorient {
	NSLog(@"Rotated!");
}
*/

- (void) postGameOver {
	CGRect rect = frameview.bounds;
	rect.origin.x = 0.5*rect.size.width;
	rect.origin.y = rect.size.height - 4;
	rect.size.width = 4;
	rect.size.height = 4;
	GameOverView *menuview = [[[GameOverView alloc] initWithFrame:frameview.bounds buttonFrame:rect belowButton:NO] autorelease];
	[frameview postPopMenu:menuview];	
}

- (void) displayModalRequest:(id)special {
	if ([special isKindOfClass:[NSNull class]]) {
		/* No modal view at exit time; just continue displaying and doing nothing. */
		return;
	}
	
	if ([special isKindOfClass:[GlkFileRefPrompt class]]) {
		GlkFileRefPrompt *prompt = (GlkFileRefPrompt *)special;
		
		NSString *nibname;
		if (prompt.fmode == filemode_Read)
			nibname = @"GlkFileSelectLoad";
		else
			nibname = @"GlkFileSelectStore";
			
		GlkFileSelectViewController *viewc = [[[GlkFileSelectViewController alloc] initWithNibName:nibname prompt:prompt bundle:nil] autorelease];
		UINavigationController *navc = [[[UINavigationController alloc] initWithRootViewController:viewc] autorelease];
		if ([UINavigationController instancesRespondToSelector:@selector(setModalPresentationStyle:)]) {
			/* Requires iOS 3.2 (but it has no effect on iPhone, so just skip it in 3.1.3) */
			[navc setModalPresentationStyle:UIModalPresentationFormSheet];
		}
		[self presentModalViewController:navc animated:YES];
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

- (void) didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

@end
