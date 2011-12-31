/* IosGlkViewController.m: Main view controller class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "IosGlkViewController.h"
#import "GlkFrameView.h"
#import "GlkWindowView.h"
#import "GlkUtilTypes.h"
#import "GlkFileTypes.h"
#import "GlkFileSelectViewController.h"
#import "GlkUtilities.h"

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
- (void) viewDidLoad {
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
	NSLog(@"IosGlkViewController dealloc %x", (unsigned int)self);
	[super dealloc];
}

- (GlkFrameView *) viewAsFrameView {
	return (GlkFrameView *)self.view;
}

- (void) keyboardWillBeShown:(NSNotification*)notification {
	/* This setup assumes that the GlkFrameView extends to the bottom of the display, so the entire keyboard height needs to be subtracted from it. A more flexible plan would be to compare UIKeyboardFrameEndUserInfoKey's top edge with the bottom edge of the view. */
	NSDictionary *info = [notification userInfo];
	CGSize size = CGSizeZero;
	/* UIKeyboardFrameBeginUserInfoKey is only available in iOS 3.2 or later. Note the funny idiom for testing the presence of a weak-linked symbol. */
	if (&UIKeyboardFrameBeginUserInfoKey) {
		CGRect rect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
		rect = [self.view convertRect:rect fromView:nil];
		size = rect.size;
	}
	else {
		/* iOS 3.1.3... */
		CGRect rect = [[info objectForKey:UIKeyboardBoundsUserInfoKey] CGRectValue];
		size = rect.size;
	}
	NSLog(@"Keyboard will be shown, size %@", StringFromSize(size));
	
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
