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
#import "GlkUtilities.h"

@implementation IosGlkViewController

@synthesize glkdelegate;
@synthesize frameview;

+ (IosGlkViewController *) singleton {
	return [IosGlkAppDelegate singleton].glkviewc;
}

- (void) dealloc {
	NSLog(@"IosGlkViewController dealloc %x", (unsigned int)self);
	[super dealloc];
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
		if (winv.textfield && [winv.textfield isFirstResponder]) {
			NSLog(@"Hiding keyboard for %@", winv);
			[winv.textfield resignFirstResponder];
			break;
		}
	}
}

- (IBAction) toggleKeyboard {
	GlkWindowView *firstinputview = nil;
	
	for (GlkWindowView *winv in [frameview.windowviews allValues]) {
		if (winv.textfield && [winv.textfield isFirstResponder]) {
			NSLog(@"Hiding keyboard for %@", winv);
			[winv.textfield resignFirstResponder];
			break;
		}
		if (winv.textfield && !firstinputview)
			firstinputview = winv;
	}
	
	if (firstinputview) {
		NSLog(@"Reshowing keyboard for %@", firstinputview);
		[firstinputview.textfield becomeFirstResponder];
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

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


@end
