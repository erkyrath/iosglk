/* GlkFileSelectViewController./: View controller class for the load/save dialog
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/* This is a UIViewController, not a UITableViewController. That's because the UITableViewController class adds very little, and gets confused if you try to tell it that the UITableView is not the top-level view in its nib file.
*/

#import "GlkFileSelectViewController.h"
#import "GlkFileTypes.h"
#import "GlkAppWrapper.h"
#import "RelDateFormatter.h"
#import "GlkUtilities.h"


@implementation GlkFileSelectViewController

@synthesize tableView;
@synthesize textfield;
@synthesize prompt;
@synthesize filelist;
@synthesize dateformatter;

- (id) initWithNibName:(NSString *)nibName prompt:(GlkFileRefPrompt *)promptref bundle:(NSBundle *)nibBundle {
	self = [super initWithNibName:nibName bundle:nibBundle];
	if (self) {
		self.prompt = promptref;
		self.filelist = [NSMutableArray arrayWithCapacity:16];
		dateformatter = [[RelDateFormatter alloc] init]; // retained
		[dateformatter setDateStyle:NSDateFormatterMediumStyle];
		[dateformatter setTimeStyle:NSDateFormatterShortStyle];
	}
	return self;
}

- (void) viewDidLoad {
	[super viewDidLoad];
	
	isload = (prompt.fmode == filemode_Read);
	
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(keyboardWillBeShown:)
		name:UIKeyboardWillShowNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(keyboardWillBeHidden:)
		name:UIKeyboardWillHideNotification object:nil];
		
	//### localize and customize
	if (isload) {
		if (textfield)
			[NSException raise:@"GlkException" format:@"textfield in read-mode file selection"];
		self.navigationItem.title = @"Load";
	}
	else {
		if (!textfield)
			[NSException raise:@"GlkException" format:@"no textfield in write-mode file selection"];
		self.navigationItem.title = @"Save";
		CGRect rect = CGRectMake(0, 0, tableView.frame.size.width, 32);
		UILabel *label = [[[UILabel alloc] initWithFrame:rect] autorelease];
		label.text = @"Previously saved games:";
		label.textAlignment = UITextAlignmentCenter;
		label.textColor = [UIColor lightGrayColor];
		tableView.tableHeaderView = label;
	}
	
	UIBarButtonItem *cancelbutton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(buttonCancel:)] autorelease];
	
	self.navigationItem.leftBarButtonItem = cancelbutton;
	self.navigationItem.rightBarButtonItem = [self editButtonItem];
	
	[filelist removeAllObjects];
	NSArray *ls = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:prompt.dirname error:nil];
	if (ls) {
		for (NSString *filename in ls) {
			NSString *pathname = [prompt.dirname stringByAppendingPathComponent:filename];
			NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:pathname error:nil];
			if (!attrs)
				continue;
			if (![NSFileTypeRegular isEqualToString:[attrs fileType]])
				continue;
			
			/* We accept both dumbass-encoded strings (which were typed by the user) and "normal" strings (which were created by fileref_by_name). */
			NSString *label = StringFromDumbEncoding(filename);
			if (!label)
				label = filename;
			
			GlkFileThumb *thumb = [[[GlkFileThumb alloc] init] autorelease];
			thumb.filename = filename;
			thumb.pathname = pathname;
			thumb.modtime = [attrs fileModificationDate];
			thumb.label = label;
			
			[filelist addObject:thumb];
		}
	}
	
	[filelist sortUsingSelector:@selector(compareModTime:)];
	
	if (filelist.count == 0)
		[self addBlankThumb];
}

- (void) viewDidAppear:(BOOL)animated {
	if (textfield) {
		[textfield becomeFirstResponder];
	}
}

- (void) dealloc {
	self.prompt = nil;
	self.filelist = nil;
	self.dateformatter = nil;
	[super dealloc];
}

- (void) addBlankThumb {
	GlkFileThumb *thumb = [[[GlkFileThumb alloc] init] autorelease];
	thumb.isfake = YES;
	thumb.modtime = [NSDate date];
	thumb.label = @"No saved games"; //### localize and customize
	[filelist insertObject:thumb atIndex:0];
}

- (void) keyboardWillBeShown:(NSNotification*)notification {
	NSDictionary *info = [notification userInfo];
	//BACKC: UIKeyboardFrameEndUserInfoKey is only available in 3.2 or later. Do something else for 3.1.3.
	CGRect rect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	rect = [self.tableView convertRect:rect fromView:nil];
	/* The rect is the keyboard size in view coordinates (properly rotated). */
	CGRect tablerect = self.tableView.bounds;
	CGFloat diff = (tablerect.origin.y + tablerect.size.height) - rect.origin.y;
	
	if (diff > 0) {
		UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, diff, 0.0);
		tableView.contentInset = contentInsets;
		tableView.scrollIndicatorInsets = contentInsets;
	}
}

- (void) keyboardWillBeHidden:(NSNotification*)notification {
	tableView.contentInset = UIEdgeInsetsZero;
	tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

- (IBAction) buttonCancel:(id)sender {
	NSLog(@"buttonCancel");
	[self dismissModalViewControllerAnimated:YES];
	[[GlkAppWrapper singleton] acceptEventFileSelect];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	[tableView setEditing:editing animated:animated];
}

// Table view data source methods (see UITableViewDataSource)

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return filelist.count;
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	GlkFileThumb *thumb = nil;
	
	int row = indexPath.row;
	if (row >= 0 && row < filelist.count)
		thumb = [filelist objectAtIndex:row];
		
	return (thumb && !thumb.isfake);
}

- (UITableViewCell *) tableView:(UITableView *)tableview cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"File";

	// This is boilerplate and I haven't touched it.
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
	}
	
	GlkFileThumb *thumb = nil;
	
	int row = indexPath.row;
	if (row >= 0 && row < filelist.count)
		thumb = [filelist objectAtIndex:row];
		
	/* Make the cell look right... */
	
	if (!thumb) {
		// shouldn't happen
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		cell.textLabel.text = @"(null)";
		cell.textLabel.textColor = [UIColor blackColor];
		cell.detailTextLabel.text = @"?";
	}
	else if (thumb.isfake) {
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.textLabel.text = thumb.label;
		cell.textLabel.textColor = [UIColor lightGrayColor];
		cell.detailTextLabel.text = @"";
	}
	else {
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		cell.textLabel.text = thumb.label;
		cell.textLabel.textColor = [UIColor blackColor];
		cell.detailTextLabel.text = [dateformatter stringFromDate:thumb.modtime];
	}

	return cell;
}

- (void) tableView:(UITableView *)tableview commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		GlkFileThumb *thumb = nil;
		int row = indexPath.row;
		if (row >= 0 && row < filelist.count)
			thumb = [filelist objectAtIndex:row];
		if (thumb && !thumb.isfake) {
			GlkFileThumb *thumb = [filelist objectAtIndex:row];
			NSLog(@"selector: deleting file \"%@\" (%@)", thumb.label, thumb.pathname);
			BOOL res = [[NSFileManager defaultManager] removeItemAtPath:thumb.pathname error:nil];
			if (res) {
				[filelist removeObjectAtIndex:row];
				[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
				if (filelist.count == 0) {
					[self addBlankThumb];
					[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
				}
			}
		}
	}
}

// Table view delegate (see UITableViewDelegate)

- (void) tableView:(UITableView *)tableview didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	GlkFileThumb *thumb = nil;
	int row = indexPath.row;
	if (row >= 0 && row < filelist.count)
		thumb = [filelist objectAtIndex:row];
	if (!thumb)
		return;
	if (thumb.isfake)
		return;
		
	NSLog(@"selector: selected \"%@\"", thumb.label);
	
	if (!isload) {
		/* The user has picked a filename; copy it into the field. */
		textfield.text = thumb.label;
	}
	else {
		/* The user has selected a file. */
		prompt.filename = thumb.filename;
		prompt.pathname = thumb.pathname;
		[self dismissModalViewControllerAnimated:YES];
		[[GlkAppWrapper singleton] acceptEventFileSelect];
	}
}

// Text field delegate (see UITextFieldDelegate)

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	if (tableView.indexPathForSelectedRow)
		[tableView selectRowAtIndexPath:nil animated:NO scrollPosition:UITableViewScrollPositionNone];
	return YES;
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
	/* Don't look at the text yet; the last word hasn't been spellchecked. However, we don't want to close the keyboard either. The only good answer seems to be to fire a function call with a tiny delay, and return YES to ensure that the spellcheck is accepted. */
	[self performSelector:@selector(textFieldContinueReturn:) withObject:textField afterDelay:0.0];
	return YES;
}

- (void) textFieldContinueReturn:(UITextField *)textField {
	if (![[GlkAppWrapper singleton] acceptingEventFileSelect]) {
		/* A filename must already have been accepted. */
		return;
	}
	
	NSString *label = [textfield.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (label.length == 0) {
		/* Textfield is empty. Pick a "Saved game" filename which is not already in use. */
		//### localize this string
		for (int ix=0; YES; ix++) {
			if (!ix)
				label = @"Saved game";
			else
				label = [NSString stringWithFormat:@"Saved game %d", ix];
			NSString *filename = StringToDumbEncoding(label);
			NSString *pathname = [prompt.dirname stringByAppendingPathComponent:filename];
			if (![[NSFileManager defaultManager] fileExistsAtPath:pathname])
				break;
		}
	}
	
	prompt.filename = StringToDumbEncoding(label);
	prompt.pathname = [prompt.dirname stringByAppendingPathComponent:prompt.filename];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:prompt.pathname]) {
		NSString *str = [NSString stringWithFormat:@"Replace the saved game \"%@\"?", label];
		UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:str delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Replace" otherButtonTitles:nil];
		[sheet showInView:textfield];
		return;
	}
	
	NSLog(@"textfield: selected \"%@\"", label);
	[self dismissModalViewControllerAnimated:YES];
	[[GlkAppWrapper singleton] acceptEventFileSelect];	
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		NSLog(@"textfield: confirmed selection");
		[self dismissModalViewControllerAnimated:YES];
		[[GlkAppWrapper singleton] acceptEventFileSelect];	
	}
}

- (void) didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];

	// Release any cached data, images, etc. that aren't in use.
}

@end

