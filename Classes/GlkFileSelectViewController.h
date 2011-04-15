/* GlkFileSelectViewController.h: View controller class for the load/save dialog
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>

@class GlkFileRefPrompt;
@class GlkFileThumb;

@interface GlkFileSelectViewController : UITableViewController {
	GlkFileRefPrompt *prompt;
	NSMutableArray *filelist; // array of GlkFileThumb
	NSDateFormatter *dateformatter;
}

@property (nonatomic, retain) GlkFileRefPrompt *prompt;
@property (nonatomic, retain) NSMutableArray *filelist;
@property (nonatomic, retain) NSDateFormatter *dateformatter;

- (id) initWithNibName:(NSString *)nibName prompt:(GlkFileRefPrompt *)prompt bundle:(NSBundle *)nibBundle;
- (IBAction) buttonCancel:(id)sender;

@end
