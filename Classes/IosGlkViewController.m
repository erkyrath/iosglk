//
//  IosGlkViewController.m
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import "IosGlkViewController.h"

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
	//NSLog(@"IosGlkViewController viewDidLoad");
}

- (void)dealloc {
	NSLog(@"IosGlkViewController dealloc %x", self);
	[super dealloc];
}

- (GlkFrameView *) viewAsFrameView {
	return (GlkFrameView *)self.view;
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
