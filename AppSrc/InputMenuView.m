/* InputMenuView.m: A simple pop-up menu of strings
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import "InputMenuView.h"
#import "GlkFrameView.h"
#import "GlkUtilities.h"

@implementation InputMenuView

@synthesize historymenu;
@synthesize palettemenu;
@synthesize flipbutton;
@synthesize history;

- (id) initWithFrame:(CGRect)frame buttonFrame:(CGRect)rect history:(NSArray *)historylist {
	self = [super initWithFrame:frame];
	if (self) {
		mode = inputmenu_None;
		self.history = [NSArray arrayWithArray:historylist];
		buttonrect = rect;
		
		self.flipbutton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		flipbutton.frame = buttonrect;
		[self addSubview:flipbutton];
		[flipbutton addTarget:self action:@selector(handleFlipButton:) forControlEvents:UIControlEventTouchUpInside];
	}
	return self;
}

- (void) dealloc {
	self.historymenu = nil;
	self.palettemenu = nil;
	self.flipbutton = nil;
	self.history = nil;
	[super dealloc];
}

- (GlkFrameView *) superviewAsFrameView {
	return (GlkFrameView *)self.superview;
}

- (void) setMode:(InputMenuMode)modeval {
	if (mode == modeval)
		return;
	mode = modeval;
	
	if (mode == inputmenu_History) {
		if (!historymenu) {
			[[NSBundle mainBundle] loadNibNamed:@"HistoryMenuVC" owner:self options:nil];
			[historymenu setUpFromHistory:history];
			CGRect rect = historymenu.frame;
			rect.origin.x = buttonrect.origin.x + buttonrect.size.width - rect.size.width - 10;
			rect.origin.y = buttonrect.origin.y - rect.size.height - 10;
			historymenu.frame = rect;
			[self addSubview:historymenu];
		}
		else {
			[historymenu setUpFromHistory:history];
			CGRect rect = historymenu.frame;
			rect.origin.x = buttonrect.origin.x + buttonrect.size.width - rect.size.width - 10;
			rect.origin.y = buttonrect.origin.y - rect.size.height - 10;
			historymenu.frame = rect;
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
			CGRect rect = palettemenu.frame;
			rect.origin.x = buttonrect.origin.x + buttonrect.size.width - rect.size.width - 10;
			rect.origin.y = buttonrect.origin.y - rect.size.height - 10;
			palettemenu.frame = rect;
			[self addSubview:palettemenu];
		}
		else {
			[palettemenu setUp];
			CGRect rect = palettemenu.frame;
			rect.origin.x = buttonrect.origin.x + buttonrect.size.width - rect.size.width - 10;
			rect.origin.y = buttonrect.origin.y - rect.size.height - 10;
			palettemenu.frame = rect;
			palettemenu.hidden = NO;
		}
		if (historymenu) {
			historymenu.hidden = YES;
		}
	}
}

- (void) handleFlipButton:(id)sender {
	[self.superviewAsFrameView setInputMenuMode:(mode==inputmenu_History)?inputmenu_Palette:inputmenu_History];
}

- (void) acceptCommand:(NSString *)cmd replace:(BOOL)replace close:(BOOL)closemenu {
	[self.superviewAsFrameView applyInputString:cmd replace:replace];
	
	if (closemenu)
		[self.superviewAsFrameView removeInputMenu];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[self.superviewAsFrameView removeInputMenu];
}

@end


@implementation HistoryMenuView

@synthesize baselabel;
@synthesize labels;

- (void) dealloc {
	self.baselabel = nil;
	self.labels = nil;
	[super dealloc];
}

- (void) awakeFromNib {
	[super awakeFromNib];
	labelbox = baselabel.frame;
	labelheight = labelbox.size.height;
	extraheight = self.bounds.size.height - labelheight;
	
	self.layer.cornerRadius = 4;
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
	self.bounds = rect;
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
		InputMenuView *menuview = (InputMenuView *)self.superview;
		[menuview acceptCommand:label.text replace:YES close:YES];
	}
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self selectLabel:-1];
}

@end


@implementation PaletteMenuView

@synthesize labels;

- (void) dealloc {
	selection = nil;
	self.labels = nil;
	[super dealloc];
}

- (void) awakeFromNib {
	[super awakeFromNib];
	
	self.layer.cornerRadius = 6;
}

- (void) setUp {
	selection = nil;
	self.labels = [NSMutableArray arrayWithCapacity:20];
	for (UIView *view in self.subviews) {
		if ([view isKindOfClass:[UILabel class]] && view.tag >= 0) {
			[labels addObject:view];
		}
	}
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
		InputMenuView *menuview = (InputMenuView *)self.superview;
		[self selectLabel:nil];
		[menuview acceptCommand:cmd replace:NO close:closemenu];
	}
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self selectLabel:nil];
}


@end
