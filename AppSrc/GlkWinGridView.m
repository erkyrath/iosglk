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


@implementation GlkWinGridView

+ (BOOL) supportsSecureCoding {
    return YES;
}

- (instancetype) initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    return self;
}

- (void) encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
}

- (instancetype) initWithWindow:(GlkWindowState *)winref frame:(CGRect)box margin:(UIEdgeInsets)margin {
	self = [super initWithWindow:winref frame:box margin:margin];
	if (self) {
		self.backgroundColor = [UIColor clearColor];

        self.textview =
        [[UITextView alloc] initWithFrame:self.bounds];

        _textview.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        _textview.delegate = self;
        _textview.textContainerInset = margin;
        _textview.editable = NO;
        _textview.scrollEnabled = NO;
        _textview.showsVerticalScrollIndicator = NO;
        _textview.showsHorizontalScrollIndicator = NO;
        _textview.accessibilityCustomRotors = [super accessibilityCustomRotors];
        [self addSubview:_textview];
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
	if (inputfield)
		[inputfield adjustForWindowStyles:styleset];
	//self.backgroundColor = styleset.backgroundcolor;
	[self setNeedsDisplay];
}

- (void) layoutSubviews {
	//NSLog(@"GridView: layoutSubviews");
	//### need to move or resize the text input view here
}

- (void) updateFromWindowState {
	GlkWindowGridState *gridwin = (GlkWindowGridState *)winstate;
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

    if (!anychanges)
        return;

    if (attrstring)
        [_textview.textStorage setAttributedString:attrstring];
	
	[_textview setNeedsDisplay];
}

- (void) placeInputField:(UITextField *)field holder:(UIScrollView *)holder {
	GlkWindowGridState *gridwin = (GlkWindowGridState *)winstate;
	
	CGRect realbounds = RectApplyingEdgeInsets(self.bounds, viewmargin);
	CGSize charbox = styleset.charbox;
	CGRect box;
	CGPoint marginoffset;
	marginoffset.x = styleset.margins.left + viewmargin.left;
	marginoffset.y = styleset.margins.top + viewmargin.top;

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

@end

