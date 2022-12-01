/* GlkFileSelectViewController./: View controller class for the load/save dialog
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/* This is a UIViewController, not a UITableViewController. That's because the UITableViewController class adds very little, and gets confused if you try to tell it that the UITableView is not the top-level view in its nib file.
*/

#import "GlkFileSelectViewController.h"
#import "IosGlkViewController.h"
#import "GlkFileTypes.h"
#import "GlkAppWrapper.h"
#import "RelDateFormatter.h"
#import "GlkUtilities.h"


@implementation GlkFileSelectViewController

@synthesize tableView;
@synthesize textfield;
@synthesize savebutton;
@synthesize prompt;
@synthesize usekey;
@synthesize filelist;
@synthesize dateformatter;

- (void) viewDidLoad {
	[super viewDidLoad];

    self.filelist = [NSMutableArray arrayWithCapacity:16];
    self.dateformatter = [[RelDateFormatter alloc] init];
    dateformatter.dateStyle = NSDateFormatterMediumStyle;
    dateformatter.timeStyle = NSDateFormatterShortStyle;

    self.usekey = [GlkFileThumb labelForFileUsage:(prompt.usage & fileusage_TypeMask) localize:nil];

	isload = (prompt.fmode == filemode_Read);
	
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(keyboardWillBeShown:)
		name:UIKeyboardWillShowNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(keyboardWillBeHidden:)
		name:UIKeyboardWillHideNotification object:nil];
	
	if (isload) {
		if (textfield)
			[NSException raise:@"GlkException" format:@"textfield in read-mode file selection"];
		self.navigationItem.title = NSLocalizedString([usekey stringByAppendingString:@".readtitle"], nil);
	}
	else {
		if (!textfield)
			[NSException raise:@"GlkException" format:@"no textfield in write-mode file selection"];
		
		NSString *placeholder = NSLocalizedString([usekey stringByAppendingString:@".placeholder"], nil);
		for (int ix=1; YES; ix++) {
			NSString *label = placeholder;
			if (ix >= 2)
				label = [NSString stringWithFormat:@"%@ %d", label, ix];
			NSString *filename = StringToDumbEncoding(label);
			NSString *pathname = [prompt.dirname stringByAppendingPathComponent:filename];
			if (![[NSFileManager defaultManager] fileExistsAtPath:pathname]) {
				placeholder = label;
				defaultcounter = ix;
				break;
			}
		}
		
		self.navigationItem.title = NSLocalizedString([usekey stringByAppendingString:@".writetitle"], nil);
		textfield.placeholder = placeholder;
		CGRect rect = CGRectMake(0, 0, tableView.frame.size.width, 32);
		UILabel *label = [[UILabel alloc] initWithFrame:rect];
		label.text = NSLocalizedString([usekey stringByAppendingString:@".listlabel"], nil);
		label.textAlignment = NSTextAlignmentCenter;
		label.textColor = [UIColor lightGrayColor];
		tableView.tableHeaderView = label;
	}
	
	UIBarButtonItem *cancelbutton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(buttonCancel:)];
	
	self.navigationItem.leftBarButtonItem = cancelbutton;
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
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
			
			GlkFileThumb *thumb = [[GlkFileThumb alloc] init];
			thumb.filename = filename;
			thumb.pathname = pathname;
			thumb.usage = (prompt.usage & fileusage_TypeMask);
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
	[super viewDidAppear:animated];
	if (textfield) {
		[textfield becomeFirstResponder];
	}
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if ([GlkAppWrapper singleton].acceptingEventFileSelect)
        [[GlkAppWrapper singleton] acceptEventFileSelect:prompt];
}


- (void) addBlankThumb {
	GlkFileThumb *thumb = [[GlkFileThumb alloc] init];
	thumb.isfake = YES;
	thumb.modtime = [NSDate date];
	thumb.label = NSLocalizedString([usekey stringByAppendingString:@".nofiles"], nil);
	[filelist insertObject:thumb atIndex:0];
}

- (void) keyboardWillBeShown:(NSNotification*)notification {
	NSDictionary *info = notification.userInfo;
	CGFloat diff = 0;
	CGRect rect = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
	rect = [self.tableView convertRect:rect fromView:nil];
	/* The rect is the keyboard size in view coordinates (properly rotated). */
	CGRect tablerect = self.tableView.bounds;
	diff = (tablerect.origin.y + tablerect.size.height) - rect.origin.y;
	
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
    [[GlkAppWrapper singleton] acceptEventFileSelect:prompt];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction) buttonSave:(id)sender {
	if (self.textfield)
		[self performSelector:@selector(textFieldContinueReturn:) withObject:self.textfield afterDelay:0.0];
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
		thumb = filelist[row];
		
	return (thumb && !thumb.isfake);
}

- (UITableViewCell *) tableView:(UITableView *)tableview cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"File";

	// This is boilerplate and I haven't touched it.
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
	}
	
	GlkFileThumb *thumb = nil;
	
	int row = indexPath.row;
	if (row >= 0 && row < filelist.count)
		thumb = filelist[row];
		
	/* Make the cell look right... */
	
	if (!thumb) {
		// shouldn't happen
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		cell.textLabel.text = NSLocalizedString(@"(null)", nil);
		cell.textLabel.textColor = [UIColor colorNamed:@"CustomText"];
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
        cell.textLabel.textColor = [UIColor colorNamed:@"CustomText"];
		cell.detailTextLabel.text = [dateformatter stringFromDate:thumb.modtime];
	}

	return cell;
}

- (void) tableView:(UITableView *)tableview commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		GlkFileThumb *thumb = nil;
		int row = indexPath.row;
		if (row >= 0 && row < filelist.count)
			thumb = filelist[row];
		if (thumb && !thumb.isfake) {
			GlkFileThumb *thumb = filelist[row];
			BOOL res = [[NSFileManager defaultManager] removeItemAtPath:thumb.pathname error:nil];
			if (res) {
				[filelist removeObjectAtIndex:row];
				[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
				if (filelist.count == 0) {
					[self addBlankThumb];
					[tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
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
		thumb = filelist[row];
	if (!thumb)
		return;
	if (thumb.isfake)
		return;
		
	if (!isload) {
		/* The user has picked a filename; copy it into the field. */
		textfield.text = thumb.label;
	}
	else {
		/* The user has selected a file. */
		prompt.filename = thumb.filename;
		prompt.pathname = thumb.pathname;
        [[GlkAppWrapper singleton] acceptEventFileSelect:prompt];
		[self dismissViewControllerAnimated:YES completion:nil];
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
	if (![GlkAppWrapper singleton].acceptingEventFileSelect) {
		/* A filename must already have been accepted. */
		return;
	}
	
	NSString *label = [textfield.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (label.length == 0) {
		/* Textfield is empty. Pick a "Saved game" filename which is not already in use. */
		label = NSLocalizedString([usekey stringByAppendingString:@".placeholder"], nil);
		if (defaultcounter >= 2)
			label = [NSString stringWithFormat:@"%@ %d", label, defaultcounter];
	}
	
	prompt.filename = StringToDumbEncoding(label);
	prompt.pathname = [prompt.dirname stringByAppendingPathComponent:prompt.filename];
	
	if (prompt.fmode != filemode_WriteAppend && [[NSFileManager defaultManager] fileExistsAtPath:prompt.pathname]) {
		NSString *str = [NSString stringWithFormat:NSLocalizedString([usekey stringByAppendingString:@".replacequery"], nil), label];

        UIAlertController *sheet = [UIAlertController alertControllerWithTitle:str message:nil preferredStyle:UIAlertControllerStyleActionSheet];

        [sheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"button.cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}]];

        GlkFileSelectViewController __weak *weakSelf = self;
        [sheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"button.replace", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            // Destructive button tapped.
            [self dismissViewControllerAnimated:YES completion:^{}];
            [[GlkAppWrapper singleton] acceptEventFileSelect:weakSelf.prompt];
        }]];

        UIPopoverPresentationController *popoverController = sheet.popoverPresentationController;
        if (popoverController) {
            popoverController.sourceView = self.view;
            popoverController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 0, 0);
            popoverController.permittedArrowDirections = 0;
        }

        // Present action sheet.
        [self presentViewController:sheet animated:YES completion:nil];
		return;
	}

    [[GlkAppWrapper singleton] acceptEventFileSelect:prompt];
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end

