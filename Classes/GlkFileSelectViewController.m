//
//  GlkFileSelectViewController.m
//  IosGlk
//
//  Created by Andrew Plotkin on 4/11/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import "GlkFileSelectViewController.h"


@implementation GlkFileSelectViewController


- (void) viewDidLoad {
	[super viewDidLoad];
	
	self.navigationItem.title = @"Load"; //### localize and customize
	
	UIBarButtonItem *cancelbutton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(buttonCancel:)] autorelease];
	
	self.navigationItem.leftBarButtonItem = cancelbutton;
	self.navigationItem.rightBarButtonItem = [self editButtonItem];
}

- (void) viewDidUnload {
	[super viewDidUnload];
}

- (void) dealloc {
	[super dealloc];
}

- (IBAction) buttonCancel:(id)sender {
	NSLog(@"buttonCancel");
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	NSLog(@"setEditing now %d", editing);
}

- (void) didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];

	// Release any cached data, images, etc. that aren't in use.
}


@end
