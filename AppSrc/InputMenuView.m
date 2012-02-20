/* InputMenuView.m: A simple pop-up menu of strings
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
@synthesize historymenu;
@synthesize palettemenu;
@synthesize flipbutton;
@synthesize history;

- (id) initWithFrame:(CGRect)frame buttonFrame:(CGRect)rect view:(GlkWindowView *)winval history:(NSArray *)historylist {
	self = [super initWithFrame:frame buttonFrame:rect];
	if (self) {
		mode = inputmenu_None;
		self.winview = winval;
		self.history = [NSArray arrayWithArray:historylist];
		
		self.flipbutton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		flipbutton.frame = buttonrect;
		[self addSubview:flipbutton];
		[flipbutton addTarget:self action:@selector(handleFlipButton:) forControlEvents:UIControlEventTouchUpInside];
	}
	return self;
}

- (void) dealloc {
	self.winview = nil;
	self.historymenu = nil;
	self.palettemenu = nil;
	self.flipbutton = nil;
	self.history = nil;
	[super dealloc];
}

- (void) loadContent {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	InputMenuMode curmode = [defaults integerForKey:@"InputMenuMode"];
	if (curmode != inputmenu_History && curmode != inputmenu_Palette)
		curmode = inputmenu_Palette;
	
	[self setMode:curmode];
}

- (void) setMode:(InputMenuMode)modeval {
	if (mode == modeval)
		return;
	mode = modeval;
	
	if (mode == inputmenu_History) {
		if (!historymenu) {
			[[NSBundle mainBundle] loadNibNamed:@"HistoryMenuVC" owner:self options:nil];
			[historymenu setUpFromHistory:history];
			[self resizeContentTo:historymenu.frame.size animated:NO];
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
			[[NSBundle mainBundle] loadNibNamed:@"PaletteMenuVC" owner:self options:nil];
			[palettemenu setUp];
			[self resizeContentTo:palettemenu.frame.size animated:NO];
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

- (void) handleFlipButton:(id)sender {
	InputMenuMode newmode = (mode==inputmenu_History)?inputmenu_Palette:inputmenu_History;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:newmode forKey:@"InputMenuMode"];

	[self setMode:newmode];
}

- (void) acceptCommand:(NSString *)cmd replace:(BOOL)replace close:(BOOL)closemenu {
	if (!winview || !winview.inputfield)
		return;
	
	[winview.inputfield applyInputString:cmd replace:replace];
	
	if (closemenu)
		[self.superviewAsFrameView removePopMenu];
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
	[baselabel removeFromSuperview];
	if (self.labels) {
		for (UILabel *label in labels)
			[label removeFromSuperview];
	}
	
	selection = -1;

	CGRect rect = labelbox;

	self.labels = [NSMutableArray arrayWithCapacity:history.count];
	for (NSString *str in history) {
		UILabel *label = [[[UILabel alloc] initWithFrame:rect] autorelease];
		label.backgroundColor = nil;
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
	UITouch *touch = [[event touchesForView:self] anyObject];
	CGPoint loc = [touch locationInView:self];
	int val = floorf((loc.y - labelbox.origin.y) / labelheight);
	[self selectLabel:val];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [[event touchesForView:self] anyObject];
	CGPoint loc = [touch locationInView:self];
	int val = floorf((loc.y - labelbox.origin.y) / labelheight);
	[self selectLabel:val];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (selection >= 0 && selection < labels.count) {
		UILabel *label = [labels objectAtIndex:selection];
		if (menuview && menuview.superview) {
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
