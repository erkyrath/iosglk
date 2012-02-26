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
#import "GlkLibrary.h"
#import "GlkUtilities.h"

#define MAX_HISTORY_LENGTH (12)

@implementation IosGlkViewController

@synthesize glkdelegate;
@synthesize frameview;
@synthesize commandhistory;

+ (IosGlkViewController *) singleton {
	return [IosGlkAppDelegate singleton].glkviewc;
}

- (void) dealloc {
	NSLog(@"IosGlkViewController dealloc %x", (unsigned int)self);
	self.frameview = nil;
	self.commandhistory = nil;
	[super dealloc];
}

- (void) didFinishLaunching {
	/* Subclasses may override this */

	self.commandhistory = [NSMutableArray arrayWithCapacity:MAX_HISTORY_LENGTH];
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
	//NSLog(@"viewDidUnload");
	self.frameview = nil;
}

- (void) viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[frameview removePopMenuAnimated:NO];
}

- (void) viewDidLoad {
	IosGlkAppDelegate *appdelegate = [IosGlkAppDelegate singleton];
	//NSLog(@"viewDidLoad (library is %x)", (unsigned int)(appdelegate.library));
	if (appdelegate.library)
		[frameview requestLibraryState:appdelegate.glkapp];
}

- (void) buildPopMenu:(PopMenuView *)menuview {
	[[NSBundle mainBundle] loadNibNamed:@"PopBoxView" owner:menuview options:nil];
}

- (void) buildMoreView:(MoreBoxView *)moreview {
	[[NSBundle mainBundle] loadNibNamed:@"MoreBoxView" owner:moreview options:nil];
}

- (void) keyboardWillBeShown:(NSNotification*)notification {
	NSDictionary *info = [notification userInfo];
	CGRect rect = CGRectZero;
	/* UIKeyboardFrameEndUserInfoKey is only available in iOS 3.2 or later. Note the funny idiom for testing the presence of a weak-linked symbol. */
	if (&UIKeyboardFrameEndUserInfoKey) {
		rect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
		rect = [self.view.window convertRect:rect fromWindow:nil];
		rect = [self.view convertRect:rect fromView:self.view.window];
	}
	else {
		/* iOS 3.1.3... */
		rect = [[info objectForKey:UIKeyboardBoundsUserInfoKey] CGRectValue];
		rect.origin.x = 0;
		rect.origin.y = self.view.bounds.size.height - rect.size.height;
	}
	NSLog(@"Keyboard will be shown, box %@ (root view coords)", StringFromRect(rect));
	
	/* This rect is in root view coordinates. */
	
	[[self frameview] setKeyboardBox:rect];
}

- (void) keyboardWillBeHidden:(NSNotification*)notification {
	NSLog(@"Keyboard will be hidden");
	[frameview setKeyboardBox:CGRectZero];
}

- (void) hideKeyboard {
	for (GlkWindowView *winv in [frameview.windowviews allValues]) {
		if (winv.inputfield && [winv.inputfield isFirstResponder]) {
			NSLog(@"Hiding keyboard for %@", winv);
			[winv.inputfield resignFirstResponder];
			break;
		}
	}
}

- (IBAction) toggleKeyboard {
	GlkWindowView *firstinputview = nil;
	
	for (GlkWindowView *winv in [frameview.windowviews allValues]) {
		if (winv.inputfield && [winv.inputfield isFirstResponder]) {
			NSLog(@"Hiding keyboard for %@", winv);
			[winv.inputfield resignFirstResponder];
			break;
		}
		if (winv.inputfield && !firstinputview)
			firstinputview = winv;
	}
	
	if (firstinputview) {
		NSLog(@"Reshowing keyboard for %@", firstinputview);
		[firstinputview.inputfield becomeFirstResponder];
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
	
	if (str.length < 2)
		return;
	
	[commandhistory removeObject:str];
	[commandhistory addObject:str];
	if (commandhistory.count > MAX_HISTORY_LENGTH) {
		NSRange range;
		range.location = 0;
		range.length = commandhistory.count - MAX_HISTORY_LENGTH;
		[commandhistory removeObjectsInRange:range];
	}
}

- (void) didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

@end
