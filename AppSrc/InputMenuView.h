/* InputMenuView.h: A simple pop-up menu of strings
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import <UIKit/UIKit.h>

typedef enum InputMenuMode_enum {
	inputmenu_None = 0,
	inputmenu_History = 1,
	inputmenu_Palette = 2,
} InputMenuMode;

@class HistoryMenuView;
@class PaletteMenuView;

@interface InputMenuView : UIView {
	HistoryMenuView *historymenu;
	PaletteMenuView *palettemenu;
	UIButton *flipbutton;
	
	InputMenuMode mode;
	CGRect buttonrect;
	NSArray *history;
}

@property (nonatomic, retain) IBOutlet HistoryMenuView *historymenu;
@property (nonatomic, retain) IBOutlet PaletteMenuView *palettemenu;
@property (nonatomic, retain) UIButton *flipbutton;
@property (nonatomic, retain) NSArray *history;

- (id) initWithFrame:(CGRect)frame buttonFrame:(CGRect)rect history:(NSArray *)historylist;
- (void) setMode:(InputMenuMode)mode;
- (void) acceptCommand:(NSString *)cmd replace:(BOOL)replace close:(BOOL)closemenu;

@end


@interface HistoryMenuView : UIView {
	UILabel *baselabel;
	NSMutableArray *labels;
	
	CGRect labelbox;
	CGFloat labelheight;
	CGFloat extraheight;
	
	int selection;
}

@property (nonatomic, retain) IBOutlet UILabel *baselabel;
@property (nonatomic, retain) NSMutableArray *labels;

- (void) setUpFromHistory:(NSArray *)history;
- (void) selectLabel:(int)val;

@end


@interface PaletteMenuView : UIView {
	NSMutableArray *labels;
	
	UILabel *selection; // not retained; always refers to an entry in labels
}

@property (nonatomic, retain) NSMutableArray *labels;

- (void) setUp;
- (void) selectLabel:(UILabel *)val;

@end
