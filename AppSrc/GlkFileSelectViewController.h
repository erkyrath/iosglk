/* GlkFileSelectViewController.h: View controller class for the load/save dialog
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>

@class GlkFileRefPrompt;
@class GlkFileThumb;

@interface GlkFileSelectViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIActionSheetDelegate> {
	UITableView *tableView;
	UITextField *textfield; /* if this is a save dialog */
	UIButton *savebutton; /* if this is a save dialog */
	
	BOOL isload;
	GlkFileRefPrompt *prompt;
	NSString *usekey;
	int defaultcounter;
	NSMutableArray *filelist; // array of GlkFileThumb
	NSDateFormatter *dateformatter;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UITextField *textfield;
@property (nonatomic, strong) IBOutlet UIButton *savebutton;
@property (nonatomic, strong) GlkFileRefPrompt *prompt;
@property (nonatomic, strong) NSString *usekey;
@property (nonatomic, strong) NSMutableArray *filelist;
@property (nonatomic, strong) NSDateFormatter *dateformatter;

- (void) addBlankThumb;
- (IBAction) buttonCancel:(id)sender;
- (IBAction) buttonSave:(id)sender;
- (void) textFieldContinueReturn:(UITextField *)textField;

@end
