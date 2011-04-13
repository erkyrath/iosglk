//
//  GlkFileSelectViewController.h
//  IosGlk
//
//  Created by Andrew Plotkin on 4/11/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GlkFileRefPrompt;
@class GlkFileThumb;

@interface GlkFileSelectViewController : UITableViewController {
	GlkFileRefPrompt *prompt;
	NSMutableArray *filelist;
}

@property (nonatomic, retain) GlkFileRefPrompt *prompt;
@property (nonatomic, retain) NSMutableArray *filelist;

- (id) initWithNibName:(NSString *)nibName prompt:(GlkFileRefPrompt *)prompt bundle:(NSBundle *)nibBundle;
- (IBAction) buttonCancel:(id)sender;

@end
