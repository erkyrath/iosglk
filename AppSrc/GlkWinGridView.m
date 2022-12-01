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
    GlkWindowGridState *state = (GlkWindowGridState *)self.winstate;
    CGFloat desiredHeight = state.height * state.styleset.charbox.height - state.styleset.leading + state.styleset.margintotal.height;
    CGFloat desiredWidth = (state.width + 2) * state.styleset.charbox.width + state.styleset.margintotal.width;

    if (_textview.frame.size.height != desiredHeight || _textview.frame.size.width != desiredWidth) {
        CGRect frame = _textview.frame;
        frame.size.height = desiredHeight;
        frame.size.width = desiredWidth;
        _textview.frame = frame;
    }
}

- (void) updateFromWindowState {
	GlkWindowGridState *state = (GlkWindowGridState *)self.winstate;

	BOOL anychanges = NO;

    NSAttributedString *attrstring = state.attrstring;
	
    if (attrstring && attrstring.length && ![attrstring.string isEqualToString:_textview.text])
        anychanges = YES;

    if (![_textview.backgroundColor isEqual:state.styleset.backgroundcolor]) {
        _textview.backgroundColor = state.styleset.backgroundcolor;
        anychanges = YES;
    }
    if (!UIEdgeInsetsEqualToEdgeInsets(_textview.textContainerInset, state.styleset.margins)) {
        _textview.textContainerInset = state.styleset.margins;
        anychanges = YES;
    }

    CGFloat newHeight = state.height * state.styleset.charbox.height + state.styleset.margintotal.height - state.styleset.leading;
    if (newHeight != _textview.frame.size.height)
        anychanges = YES;
    if (!anychanges)
        return;

    if (attrstring)
        [_textview.textStorage setAttributedString:attrstring];

	[_textview setNeedsDisplay];
}

- (void) placeInputField:(UITextField *)field holder:(UIScrollView *)holder {
	GlkWindowGridState *gridwin = (GlkWindowGridState *)self.winstate;

    NSUInteger location = gridwin.cury * (gridwin.width + 1) + gridwin.curx + 2;
    UITextPosition *start = [_textview positionFromPosition:_textview.beginningOfDocument inDirection:UITextLayoutDirectionRight offset:location];
    UITextPosition *end = [_textview positionFromPosition:start inDirection:UITextLayoutDirectionRight offset:gridwin.width - gridwin.curx + 1];
    UITextRange *textRange = [_textview textRangeFromPosition:start toPosition:end];

    CGRect box = [_textview firstRectForRange:textRange];
    box.origin.y += gridwin.styleset.leading;

	field.frame = CGRectMake(0, 0, box.size.width, box.size.height);
	holder.contentSize = box.size;
	holder.frame = box;
	if (!holder.superview)
		[self addSubview:holder];
}

- (void) updateFromUIState:(NSDictionary *)state {
    [super updateFromUIState:state];
    if (_textview) {
        NSNumber *location = state[@"selectionLoc"];
        NSNumber *length = state[@"selectionLen"];
        if (location && length) {
            _textview.selectedRange = NSMakeRange(location.integerValue, length.integerValue);
        }
    }
}

@end

