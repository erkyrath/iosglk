/* GlkFileSelectViewController./: View controller class for the load/save dialog
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "GlkFileSelectViewController.h"
#import "GlkFileTypes.h"
#import "GlkAppWrapper.h"
#import "GlkUtilities.h"


@implementation GlkFileSelectViewController

@synthesize prompt;
@synthesize filelist;
@synthesize dateformatter;

- (id) initWithNibName:(NSString *)nibName prompt:(GlkFileRefPrompt *)promptref bundle:(NSBundle *)nibBundle {
	self = [super initWithNibName:nibName bundle:nibBundle];
	if (self) {
		self.prompt = promptref;
		self.filelist = [NSMutableArray arrayWithCapacity:16];
		dateformatter = [[NSDateFormatter alloc] init]; // retained
		[dateformatter setDateStyle:NSDateFormatterMediumStyle];
		[dateformatter setTimeStyle:NSDateFormatterMediumStyle];
		dateformatter.doesRelativeDateFormatting = YES;
	}
	return self;
}

- (void) viewDidLoad {
	[super viewDidLoad];
	
	self.navigationItem.title = @"Load"; //### localize and customize
	
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
}

- (void) viewDidUnload {
	[super viewDidUnload];
}

- (void) dealloc {
	self.prompt = nil;
	self.filelist = nil;
	self.dateformatter = nil;
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


// Table view data source methods (see UITableViewDataSource)

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return filelist.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";

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
		cell.textLabel.text = @"(null)";
		cell.detailTextLabel.text = @"?";
	}
	else {
		cell.textLabel.text = thumb.label;
		cell.detailTextLabel.text = [dateformatter stringFromDate:thumb.modtime];
	}

	return cell;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		int row = indexPath.row;
		if (row >= 0 && row < filelist.count) {
			GlkFileThumb *thumb = [filelist objectAtIndex:row];
			NSLog(@"selector: deleting file \"%@\" (%@)", thumb.label, thumb.pathname);
			BOOL res = [[NSFileManager defaultManager] removeItemAtPath:thumb.pathname error:nil];
			if (res) {
				[filelist removeObjectAtIndex:row];
				[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			}
		}
	}
}

// Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	GlkFileThumb *thumb = nil;
	
	int row = indexPath.row;
	if (row >= 0 && row < filelist.count)
		thumb = [filelist objectAtIndex:row];
	if (!thumb)
		return;
		
	NSLog(@"selector: selected \"%@\"", thumb.label);
	prompt.filename = thumb.filename;
	prompt.pathname = thumb.pathname;
	[self dismissModalViewControllerAnimated:YES];
	[[GlkAppWrapper singleton] acceptEventSpecial];
}


- (void) didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];

	// Release any cached data, images, etc. that aren't in use.
}

@end

