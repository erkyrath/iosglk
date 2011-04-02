/* IosGlkViewController.m: Main view controller class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "IosGlkViewController.h"
#import "GlkFrameView.h"
#import "GlkWindowView.h"
#include "GlkUtilities.h"

@implementation IosGlkViewController



/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Custom initialization
	}
	return self;
}
*/




// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
	NSLog(@"IosGlkViewController viewDidLoad");
	
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(keyboardWillBeShown:)
		name:UIKeyboardWillShowNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(keyboardWillBeHidden:)
		name:UIKeyboardWillHideNotification object:nil];
}

- (void) dealloc {
	NSLog(@"IosGlkViewController dealloc %x", self);
	[super dealloc];
}

- (GlkFrameView *) viewAsFrameView {
	return (GlkFrameView *)self.view;
}

- (void) keyboardWillBeShown:(NSNotification*)notification {
	NSDictionary *info = [notification userInfo];
	//BACKC: UIKeyboardFrameBeginUserInfoKey is only available in 3.2 or later. Do something else for 3.1.3.
	CGRect rect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
	rect = [self.view convertRect:rect fromView:nil];
	CGSize size = rect.size;
	NSLog(@"Keyboard will be shown, size %@", StringFromSize(size));
	
	//### we could do that clever scroll-inset trick from "Managing the Keyboard"
	[[self viewAsFrameView] setKeyboardHeight:size.height];
}

- (void) keyboardWillBeHidden:(NSNotification*)notification {
	NSLog(@"Keyboard will be hidden");
	[[self viewAsFrameView] setKeyboardHeight:0];
}

- (void) hideKeyboard {
	GlkFrameView *frameview = [self viewAsFrameView];
	for (GlkWindowView *winv in [frameview.windowviews allValues]) {
		if (winv.textfield && [winv.textfield isFirstResponder]) {
			NSLog(@"Hiding keyboard for %@", winv);
			[winv.textfield resignFirstResponder];
			break;
		}
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
