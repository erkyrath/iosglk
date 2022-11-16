/* GlkWinGridView.m: Glk textgrid window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "GlkWinGridView.h"
#import "IosGlkViewController.h"
#import "GlkWindowState.h"
#import "GlkAppWrapper.h"
#import "StyleSet.h"
#import "CmdTextField.h"
#import "GlkUtilities.h"

@interface GlkWinGridView () {
    NSLayoutConstraint *textviewHeightConstraint;
}

@end

@implementation GlkWinGridView

- (instancetype) initWithWindow:(GlkWindowState *)winref frame:(CGRect)box margin:(UIEdgeInsets)margin {
    self = [super initWithWindow:winref frame:box margin:margin];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        self.textview =
        [[UITextView alloc] initWithFrame:self.bounds];

        _textview.translatesAutoresizingMaskIntoConstraints = NO;

        _textview.delegate = self;
        _textview.textContainerInset = margin;
        _textview.editable = NO;
        _textview.scrollEnabled = NO;
        _textview.showsVerticalScrollIndicator = NO;
        _textview.showsHorizontalScrollIndicator = NO;
        _textview.accessibilityTraits = UIAccessibilityTraitStaticText;

        [self addSubview:_textview];

        UILayoutGuide *guide = self.layoutMarginsGuide;

        [_textview.topAnchor constraintEqualToAnchor:guide.topAnchor].active = YES;
        [_textview.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor].active = YES;
        [_textview.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor].active = YES;

//        textviewHeightConstraint = [_textview.heightAnchor constraintEqualToConstant:self.bounds.size.height];
//        textviewHeightConstraint.active = YES;

        /* Without this contentMode setting, any window resize would cause weird font scaling. */
        self.contentMode = UIViewContentModeRedraw;
        IosGlkViewController *viewc = [IosGlkViewController singleton];
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:viewc action:@selector(textTapped:)];
        [_textview addGestureRecognizer:recognizer];
        recognizer.delegate = viewc;
    }
    return self;
}

- (void) uncacheLayoutAndStyles {
	if (self.inputfield)
		[self.inputfield adjustForWindowStyles:self.styleset];
	[self setNeedsDisplay];
}

- (void) layoutSubviews {
    [super layoutSubviews];
	NSLog(@"GridView: layoutSubviews");
    GlkWindowGridState *state = (GlkWindowGridState *)self.winstate;
    NSLog(@"state.height: %d", state.height);
    NSLog(@"state.styleset.charbox.height: %f", state.styleset.charbox.height);
    NSLog(@"self.frame: %@", NSStringFromCGRect(self.frame));
    NSLog(@"textview.frame: %@", NSStringFromCGRect(_textview.frame));
    NSLog(@"state.styleset.margintotal.height: %f", state.styleset.margintotal.height);
    NSLog(@"state.styleset.charbox.height (%f) * state.height (%d) (%f) + state.styleset.margintotal.height (%f) = %f", state.styleset.charbox.height, state.height, state.styleset.charbox.height * state.height, state.styleset.margintotal.height, state.styleset.charbox.height * state.height + state.styleset.margintotal.height);
    NSLog(@"state.styleset.charbox.width (%f) * state.width (%d) (%f) + state.styleset.margintotal.width (%f) = %f", state.styleset.charbox.width, state.height, state.styleset.charbox.width * state.width, state.styleset.margintotal.width, state.styleset.charbox.width * state.width + state.styleset.margintotal.width);

	//### need to move or resize the text input view here
}

- (void) updateFromWindowState {
	GlkWindowGridState *gridwin = (GlkWindowGridState *)self.winstate;

    NSLog(@"GlkWinGridView updateFromWindowState");
    NSLog(@"state.height: %d", gridwin.height);
    NSLog(@"state.styleset.charbox.height: %f", gridwin.styleset.charbox.height);
    NSLog(@"textview.frame: %@", NSStringFromCGRect(_textview.frame));
    NSLog(@"self.frame: %@", NSStringFromCGRect(self.frame));

	BOOL anychanges = NO;

    NSAttributedString *attrstring = gridwin.attrstring;
	
    if (attrstring && attrstring.length && ![attrstring.string isEqualToString:_textview.text])
        anychanges = YES;

    if (![_textview.backgroundColor isEqual:gridwin.styleset.backgroundcolor]) {
        _textview.backgroundColor = gridwin.styleset.backgroundcolor;
        anychanges = YES;
    }
    if (!UIEdgeInsetsEqualToEdgeInsets(_textview.textContainerInset, gridwin.styleset.margins)) {
        _textview.textContainerInset = gridwin.styleset.margins;
        anychanges = YES;
    }

    CGFloat newHeight = gridwin.height * gridwin.styleset.charbox.height + gridwin.styleset.margintotal.height;
    if (newHeight != self.bounds.size.height)
        anychanges = YES;
    if (!anychanges)
        return;

    if (attrstring)
        [_textview.textStorage setAttributedString:attrstring];

//    textviewHeightConstraint.constant = self.frame.size.height;
//    CGRect frame = self.frame;
//    frame.size.height = newHeight;
//    self.frame = frame;

	[_textview setNeedsDisplay];
}

- (void) placeInputField:(UITextField *)field holder:(UIScrollView *)holder {
	GlkWindowGridState *gridwin = (GlkWindowGridState *)self.winstate;
	
	CGRect realbounds = RectApplyingEdgeInsets(self.bounds, self.viewmargin);
	CGSize charbox = self.styleset.charbox;
	CGRect box;
	CGPoint marginoffset;
	marginoffset.x = self.styleset.margins.left + self.viewmargin.left;
	marginoffset.y = self.styleset.margins.top + self.viewmargin.top;

	box.origin.x = marginoffset.x + gridwin.curx * charbox.width;
	if (box.origin.x >= realbounds.size.width * 0.75)
		box.origin.x = realbounds.size.width * 0.75;
	box.size.width = realbounds.size.width - box.origin.x;
	box.origin.y = marginoffset.y + gridwin.cury * charbox.height;
	box.size.height = 24;
	if (box.origin.y + box.size.height > realbounds.size.height)
		box.origin.y = realbounds.size.height - box.size.height;

	field.frame = CGRectMake(0, 0, box.size.width, box.size.height);
	holder.contentSize = box.size;
	holder.frame = box;
	if (!holder.superview)
		[self addSubview:holder];
}

- (void) updateFromUIState:(NSDictionary *)state {
    [super updateFromUIState:state];
    NSLog(@"GlkWinGridView %@ updateFromUIState", self.tagobj);
    if (_textview) {
        NSNumber *location = state[@"selectionLoc"];
        NSNumber *length = state[@"selectionLen"];
        if (location && length) {
            _textview.selectedRange = NSMakeRange(location.integerValue, length.integerValue);
        }
    }
}

@end

