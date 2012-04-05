/* InputMenuView.m: A popmenu subclass that can display the command history or common-verb palette
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import "InputMenuView.h"
#import "GlkFrameView.h"
#import "GlkWindowView.h"
#import "CmdTextField.h"
#import "GlkUtilities.h"

@implementation InputMenuView

@synthesize winview;
@synthesize historybutton;
@synthesize palettebutton;
@synthesize historymenu;
@synthesize palettemenu;
@synthesize history;

- (id) initWithFrame:(CGRect)frame buttonFrame:(CGRect)rect view:(GlkWindowView *)winval history:(NSArray *)historylist {
	self = [super initWithFrame:frame buttonFrame:rect belowButton:NO];
	if (self) {
		mode = inputmenu_None;
		self.winview = winval;
		self.history = [NSArray arrayWithArray:historylist];
	}
	return self;
}

- (void) dealloc {
	self.winview = nil;
	self.historymenu = nil;
	self.palettemenu = nil;
	self.history = nil;
	[super dealloc];
}

- (NSString *) bottomDecorNib {
	return @"InputMenuDecor";
}

- (void) loadContent {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	InputMenuMode curmode = [defaults integerForKey:@"InputMenuMode"];
	if (curmode != inputmenu_History && curmode != inputmenu_Palette)
		curmode = inputmenu_Palette;
	
	UIImage *img;
	img = [historybutton backgroundImageForState:UIControlStateSelected];
	img = [img stretchableImageWithLeftCapWidth:img.size.width/2 topCapHeight:img.size.height/2];
	[historybutton setBackgroundImage:img forState:UIControlStateSelected];
	[historybutton setBackgroundImage:img forState:UIControlStateSelected|UIControlStateHighlighted];
	[palettebutton setBackgroundImage:img forState:UIControlStateSelected];
	[palettebutton setBackgroundImage:img forState:UIControlStateSelected|UIControlStateHighlighted];
	
	[self setMode:curmode];
}

- (void) setMode:(InputMenuMode)modeval {
	if (mode == modeval)
		return;
	mode = modeval;
	
	historybutton.selected = (mode == inputmenu_History);
	palettebutton.selected = (mode == inputmenu_Palette);
	
	if (mode == inputmenu_History) {
		if (!historymenu) {
			[[NSBundle mainBundle] loadNibNamed:@"HistoryMenuView" owner:self options:nil];
			[historymenu setUpFromHistory:history];
			[self resizeContentTo:historymenu.frame.size animated:YES];
			[content addSubview:historymenu];
		}
		else {
			[historymenu setUpFromHistory:history];
			[self resizeContentTo:historymenu.frame.size animated:YES];
			historymenu.hidden = NO;
		}
		if (palettemenu) {
			palettemenu.hidden = YES;
		}
	}
	else if (mode == inputmenu_Palette) {
		if (!palettemenu) {
			[[NSBundle mainBundle] loadNibNamed:@"PaletteMenuView" owner:self options:nil];
			[palettemenu setUp];
			[self resizeContentTo:palettemenu.frame.size animated:YES];
			[content addSubview:palettemenu];
		}
		else {
			[palettemenu setUp];
			[self resizeContentTo:palettemenu.frame.size animated:YES];
			palettemenu.hidden = NO;
		}
		if (historymenu) {
			historymenu.hidden = YES;
		}
	}
}

- (void) handlePaletteButton:(id)sender {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:inputmenu_Palette forKey:@"InputMenuMode"];

	[self setMode:inputmenu_Palette];
}

- (void) handleHistoryButton:(id)sender {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:inputmenu_History forKey:@"InputMenuMode"];
	
	[self setMode:inputmenu_History];
}

- (void) acceptCommand:(NSString *)cmd replace:(BOOL)replace close:(BOOL)closemenu {
	if (!winview || !winview.inputfield)
		return;
	
	[winview.inputfield applyInputString:cmd replace:replace];
	
	if (closemenu)
		[self.superviewAsFrameView removePopMenuAnimated:YES];
}

@end


@implementation HistoryMenuView

@synthesize menuview;
@synthesize baselabel;
@synthesize labels;

- (void) dealloc {
	self.menuview = nil;
	self.baselabel = nil;
	self.labels = nil;
	[super dealloc];
}

- (void) awakeFromNib {
	[super awakeFromNib];
	labelbox = baselabel.frame;
	labelheight = labelbox.size.height;
	extraheight = self.bounds.size.height - labelheight;
}

- (void) setUpFromHistory:(NSArray *)history {
	/* The iPhone only has room for a few items. On the iPad we allow more. */
	int maxlen = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? 6 : 12;
	if (history.count > maxlen) {
		NSRange range;
		range.location = history.count - maxlen;
		range.length = maxlen;
		history = [history subarrayWithRange:range];
	}
	
	[baselabel removeFromSuperview];
	if (self.labels) {
		for (UILabel *label in labels)
			[label removeFromSuperview];
	}
	
	selection = -1;
	disabled = NO;
	
	if (history.count == 0) {
		disabled = YES;
		history = [NSArray arrayWithObject:@"(you haven’t done much yet)"]; //###localize
	}

	CGRect rect = labelbox;

	self.labels = [NSMutableArray arrayWithCapacity:history.count];
	for (NSString *str in history) {
		UILabel *label = [[[UILabel alloc] initWithFrame:rect] autorelease];
		label.font = baselabel.font;
		if (!disabled)
			label.textColor = baselabel.textColor;
		else
			label.textColor = [UIColor colorWithWhite:0.5 alpha:1];
		label.backgroundColor = nil;
		label.shadowColor = baselabel.shadowColor;
		label.shadowOffset = baselabel.shadowOffset;
		label.opaque = NO;
		label.text = str;
		[labels addObject:label];
		[self addSubview:label];
		
		rect.origin.y += labelheight;
	}
	
	rect = self.bounds;
	rect.size.height = extraheight + self.labels.count * labelheight;
	rect.size = CGSizeEven(rect.size);
	self.frame = rect;
}

- (void) selectLabel:(int)val {
	if (val < 0 || val >= labels.count)
		val = -1;
	if (selection == val)
		return;
	
	if (selection >= 0 && selection < labels.count) {
		UILabel *label = [labels objectAtIndex:selection];
		label.backgroundColor = nil;
	}
	
	selection = val;

	if (selection >= 0 && selection < labels.count) {
		UILabel *label = [labels objectAtIndex:selection];
		label.backgroundColor = [UIColor whiteColor];
	}
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if (disabled)
		return;
	UITouch *touch = [[event touchesForView:self] anyObject];
	CGPoint loc = [touch locationInView:self];
	int val = floorf((loc.y - labelbox.origin.y) / labelheight);
	[self selectLabel:val];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if (disabled)
		return;
	UITouch *touch = [[event touchesForView:self] anyObject];
	CGPoint loc = [touch locationInView:self];
	int val = floorf((loc.y - labelbox.origin.y) / labelheight);
	[self selectLabel:val];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (disabled)
		return;
	if (selection >= 0 && selection < labels.count) {
		UILabel *label = [labels objectAtIndex:selection];
		if (menuview && menuview.superview) {
			[self selectLabel:-1];
			[menuview acceptCommand:label.text replace:YES close:YES];
		}
	}
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self selectLabel:-1];
}

@end


@implementation PaletteMenuView

@synthesize menuview;
@synthesize labels;

- (void) dealloc {
	self.menuview = nil;
	selection = nil;
	self.labels = nil;
	[super dealloc];
}

- (void) awakeFromNib {
	[super awakeFromNib];
	origbounds = self.bounds;
}

- (void) setUp {
	selection = nil;
	self.labels = [NSMutableArray arrayWithCapacity:20];
	for (UIView *view in self.subviews) {
		if ([view isKindOfClass:[UILabel class]] && view.tag >= 0) {
			[labels addObject:view];
		}
	}
	
	self.frame = origbounds;
}

- (UILabel *) labelAtPoint:(CGPoint)loc {
	for (UILabel *label in labels) {
		if (CGRectContainsPoint(label.frame, loc))
			return label;
	}
	return nil;
}

- (void) selectLabel:(UILabel *)val {
	if (selection == val)
		return;
	
	if (selection) {
		selection.backgroundColor = nil;
	}
	
	selection = val;
	
	if (selection) {
		selection.backgroundColor = [UIColor whiteColor];
	}
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [[event touchesForView:self] anyObject];
	CGPoint loc = [touch locationInView:self];
	UILabel *label = [self labelAtPoint:loc];
	[self selectLabel:label];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [[event touchesForView:self] anyObject];
	CGPoint loc = [touch locationInView:self];
	UILabel *label = [self labelAtPoint:loc];
	[self selectLabel:label];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (selection) {
		BOOL closemenu = (selection.tag == 0);
		NSString *cmd = selection.text;
		if (menuview && menuview.superview) {
			[self selectLabel:nil];
			[menuview acceptCommand:cmd replace:NO close:closemenu];
		}
	}
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self selectLabel:nil];
}


@end
