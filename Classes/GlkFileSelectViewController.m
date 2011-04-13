//
//  GlkFileSelectViewController.m
//  IosGlk
//
//  Created by Andrew Plotkin on 4/12/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import "GlkFileSelectViewController.h"
#import "GlkUtilTypes.h"
#import "GlkAppWrapper.h"


@implementation GlkFileSelectViewController

@synthesize prompt;
@synthesize filelist;

- (id) initWithNibName:(NSString *)nibName prompt:(GlkFileRefPrompt *)promptref bundle:(NSBundle *)nibBundle {
	self = [super initWithNibName:nibName bundle:nibBundle];
	if (self) {
		self.prompt = promptref;
		self.filelist = [NSMutableArray arrayWithCapacity:16];
	}
	return self;
}

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
	self.prompt = nil;
	self.filelist = nil;
	[super dealloc];
}

- (IBAction) buttonCancel:(id)sender {
	NSLog(@"buttonCancel");
	[self dismissModalViewControllerAnimated:YES];
	[[GlkAppWrapper singleton] acceptEventSpecial];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}


// Table view data source methods

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return filelist.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	static NSString *CellIdentifier = @"Cell";

	// This is boilerplate and I haven't touched it.
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}

	// Configure the cell...

	return cell;
}


// Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	//### return that puppy and close everything
}


- (void) didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];

	// Release any cached data, images, etc. that aren't in use.
}

@end

