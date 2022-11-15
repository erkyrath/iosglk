/* GlkWinBufferView.m: Glk textbuffer window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "GlkWinBufferView.h"
#import "IosGlkAppDelegate.h"
#import "IosGlkViewController.h"
#import "GlkLibrary.h"
#import "GlkWindowState.h"
#import "GlkLibraryState.h"
#import "GlkUtilTypes.h"

#import "CmdTextField.h"
#import "MoreBoxView.h"
#import "StyleSet.h"
#import "GlkUtilities.h"

@implementation GlkWinBufferView

+ (BOOL) supportsSecureCoding {
    return YES;
}

- (instancetype) initWithWindow:(GlkWindowState *)winref frame:(CGRect)box margin:(UIEdgeInsets)margin {
	self = [super initWithWindow:winref frame:box margin:margin];
	if (self) {
		self.contentMode = UIViewContentModeRedraw;
		self.backgroundColor = [UIColor clearColor];
		
		lastLayoutBounds = CGRectNull;
        self.textview =
        [[UITextView alloc] initWithFrame:self.bounds];

        _textview.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _textview.delegate = self;
        _textview.textContainerInset = margin;
        _textview.editable = NO;
        _textview.accessibilityCustomRotors = [super accessibilityCustomRotors];

        [self addSubview:_textview];

        IosGlkViewController *viewc = [IosGlkViewController singleton];
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:viewc action:@selector(textTapped:)];
        [_textview addGestureRecognizer:recognizer];
        recognizer.delegate = viewc;
		
		self.moreview = [[MoreBoxView alloc] initWithFrame:CGRectZero];
		[[NSBundle mainBundle] loadNibNamed:@"MoreBoxView" owner:_moreview options:nil];
		CGRect rect = _moreview.frameview.frame;
		rect.origin.x = MIN(box.size.width - viewmargin.right + 4, box.size.width - (rect.size.width + 4));
		rect.origin.y = box.size.height - (rect.size.height + 4);
		_moreview.frame = rect;
		[_moreview addSubview:_moreview.frameview];
		_moreview.userInteractionEnabled = NO;
		_moreview.hidden = YES;
		[self addSubview:_moreview];
	}
	return self;
}

- (void) dealloc {
	_textview.delegate = nil;
}

- (void) setViewmargin:(UIEdgeInsets)newmargin {
	super.viewmargin = newmargin;
	
	if (_textview) {
        _textview.layoutMargins = newmargin;
		[_textview setNeedsLayout];
		[_textview setNeedsDisplay];
	}
}

/* This is called when the GlkFrameView changes size, and also (in iOS4) when the child scrollview scrolls. This is a mysterious mix of cases, but we can safely ignore the latter by only acting when the bounds actually change. 
*/
- (void) layoutSubviews {
	[super layoutSubviews];

	if (CGRectEqualToRect(lastLayoutBounds, self.bounds)) {
		return;
	}
	lastLayoutBounds = self.bounds;
	//NSLog(@"WBV: layoutSubviews to %@", StringFromRect(self.bounds));

	CGRect rect = _moreview.frameview.frame;
	rect.origin.x = MIN(lastLayoutBounds.size.width - viewmargin.right + 4, lastLayoutBounds.size.width - (rect.size.width + 4));
	rect.origin.y = lastLayoutBounds.size.height - (rect.size.height + 4);
	_moreview.frame = rect;

	_textview.frame = lastLayoutBounds;
    if (inputfield)
        [self placeInputField:inputfield holder:inputholder];
}

- (void) uncacheLayoutAndStyles {

    /* reassign styles in the textstorage NSAttributedString */

    NSTextStorage *textstorage = _textview.textStorage;
    NSMutableAttributedString *backingStorage = [textstorage mutableCopy];

    NSArray<NSDictionary *> __block *blockStyles = self.styleset.bufferattributes;
    [textstorage
     enumerateAttributesInRange:NSMakeRange(0, textstorage.length)
     options:0
     usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        // We overwrite all attributes with those in the updated
        // styles array
        id styleobject = attrs[@"GlkStyle"];
        if (styleobject) {
            NSDictionary *stylesAtt = blockStyles[(NSUInteger)[styleobject intValue]];
            [backingStorage setAttributes:stylesAtt range:range];
        }
    }];

    [textstorage setAttributedString:backingStorage];

	if (inputfield)
		[inputfield adjustForWindowStyles:styleset];
	lastLayoutBounds = CGRectNull;
}

- (void) updateFromWindowState {
    GlkWindowBufferState *bufwin = (GlkWindowBufferState *)winstate;
    BOOL anychanges = NO;

    if (!bufwin.attrstring)
        bufwin.attrstring = [NSMutableAttributedString new];
    else if (bufwin.attrstring.length)
        anychanges = YES;

    NSTextStorage *textstorage = _textview.textStorage;

    if (![_textview.backgroundColor isEqual:bufwin.styleset.backgroundcolor]) {
        _textview.backgroundColor = bufwin.styleset.backgroundcolor;
        anychanges = YES;
    }
    if (!UIEdgeInsetsEqualToEdgeInsets(_textview.textContainerInset, bufwin.styleset.margins)) {
        _textview.textContainerInset = bufwin.styleset.margins;
        anychanges = YES;
    }

    if (_clearcount != bufwin.clearcount) {
        _clearcount = bufwin.clearcount;
        [textstorage setAttributedString:bufwin.attrstring];
        lastSeenCharacterIndex = 0;
        anychanges = YES;
    } else {
        [textstorage appendAttributedString:bufwin.attrstring];
    }

    if (!anychanges)
        return;

    [_textview setNeedsDisplay];

    CGRect rect = CGRectZero;
    rect.size = self.bounds.size;
    rect.origin.y = _textview.contentOffset.y + rect.size.height;

    [_textview.layoutManager ensureLayoutForBoundingRect:rect inTextContainer:_textview.textContainer];
    _nowcontentscrolling = YES;
    [_textview scrollRectToVisible:rect animated:YES];
}

/* This is invoked whenever the user types something. If we're at a "more" prompt, it pages down once, and returns YES. Otherwise, it pages all the way to the bottom and returns NO.
 */
- (BOOL) pageDownOnInput {
	if ([self moreToSee]) {
        CGRect rect = CGRectZero;
        rect.size = _textview.bounds.size;
        rect.origin.y = _textview.contentOffset.y + rect.size.height;

        [_textview scrollRectToVisible:rect animated:YES];
        _textview.scrollEnabled = NO;
        _textview.scrollEnabled = YES;
		return YES;
	}
	
	[self scrollTextViewToBottom];
	return NO;
}

- (BOOL) moreToSee {
    CGPoint bottomright = CGPointMake(_textview.bounds.size.width, _textview.contentOffset.y + _textview.bounds.size.height - _textview.contentInset.bottom);

    NSUInteger lastVisible = 0;

    lastVisible = [_textview.layoutManager characterIndexForPoint:bottomright inTextContainer:_textview.textContainer fractionOfDistanceBetweenInsertionPoints:NULL];

    if (lastVisible && _textview.layoutManager.numberOfGlyphs)
    {
        if (lastVisible > lastSeenCharacterIndex)
            lastSeenCharacterIndex = lastVisible;
        if (lastSeenCharacterIndex >= _textview.layoutManager.numberOfGlyphs - 1) {
//            NSLog(@"No unseen text");
            return NO;
        } else {
//            NSLog(@"%ld unseen glyphs", _textview.layoutManager.numberOfGlyphs - 1 - lastSeenCharacterIndex);
        }
        return YES;
    }

    return NO;
}

- (void) scrollTextViewToBottom {
    NSRange range = NSMakeRange(_textview.text.length, 0);
    [_textview scrollRangeToVisible:range];
    // an iOS bug, see https://stackoverflow.com/a/20989956/971070
    _textview.scrollEnabled = NO;
    _textview.scrollEnabled = YES;
}

- (void) setMoreFlag:(BOOL)flag {
	if (morewaiting == flag)
		return;
	
	/* NoMorePrompt is a preference that I decided to drop.
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL usemore = ![defaults boolForKey:@"NoMorePrompt"];
     if (!usemore)
     return;
     */

    morewaiting = flag;
    if (flag) {
        _moreview.alpha = 0;
        _moreview.hidden = NO;
        GlkWinBufferView __weak *weakSelf = self;
        [UIView animateWithDuration:0.5
                         animations:^{ weakSelf.moreview.alpha = 0.5; } ];
    }
    else {
        GlkWinBufferView __weak *weakSelf = self;
        [UIView animateWithDuration:0.5
                         animations:^{ weakSelf.moreview.alpha = 0; }
                         completion:^(BOOL finished) { weakSelf.moreview.hidden = YES; } ];
    }
}

/* Either the text field is brand-new, or last cycle's text field needs to be adjusted for a new request. Add it as a subview of the textview (if necessary), and move it to the right place.
*/
- (void) placeInputField:(UITextField *)field holder:(UIScrollView *)holder {
	CGRect box = [self placeForInputField];
//	NSLog(@"WBV: input field goes to %@", StringFromRect(box));
	
	field.frame = CGRectMake(0, 0, box.size.width, box.size.height);
	holder.contentSize = box.size;
	holder.frame = box;
	if (!holder.superview)
		[_textview addSubview:holder];
}

/* UIScrollView delegate methods: */

- (void) scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    /* If the scroll animation left us below the desired bottom edge, we'll extend the content height to include it. But only temporarily! This is to avoid jerkiness when the player scrolls to recover. */
    CGFloat offset = (_textview.contentOffset.y+_textview.bounds.size.height) - _textview.contentSize.height;
    if (offset > 1) {
        CGSize size = _textview.contentSize;
        size.height += offset;
        _textview.contentSize = size;
    }

    [self setMoreFlag:[self moreToSee]];
    _nowcontentscrolling = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!_nowcontentscrolling)
        [self setMoreFlag:[self moreToSee]];
}


- (CGRect) placeForInputField {
    CGRect box;

    CGFloat totalwidth = _textview.bounds.size.width;
    NSUInteger glyphs = _textview.text.length;

    // If textview is empty
    if (!glyphs) {
        box.origin.x = styleset.margins.left + viewmargin.left;
        box.size.width = totalwidth - styleset.margintotal.width;
        box.origin.y = 0;
        box.size.height = 24;
        return box;
    }

    UITextPosition *start = [_textview positionFromPosition:_textview.endOfDocument inDirection:UITextLayoutDirectionLeft offset:1];
    UITextRange *textRange = [_textview textRangeFromPosition:start toPosition:_textview.endOfDocument];

    CGRect fragmentRect = [_textview firstRectForRange:textRange];

    // If layout is not done?
//    if (self.lastLaidOutLine < firstsline+self.slines.count) {
//        box.origin.x = styleset.margins.left + viewmargin.left;
//        box.size.width = totalwidth - styleset.margintotal.width;
//        box.origin.y = _textview.bounds.size.height;
//        box.size.height = 24;
//        return box;
//    }

    CGFloat ptx = CGRectGetMaxX(fragmentRect);
    if (ptx >= totalwidth * 0.75)
        ptx = totalwidth * 0.75;

    box.origin.x = ptx;
    box.size.width = (totalwidth - styleset.margins.right) - ptx;
    box.origin.y = fragmentRect.origin.y;
    box.size.height = fragmentRect.size.height;

    return box;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    NSLog(@"GlkWinBufferView encodeRestorableStateWithCoder");
    [coder encodeInteger:lastSeenCharacterIndex forKey:@"lastSeenCharacterIndex"];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    lastSeenCharacterIndex = [coder decodeIntegerForKey:@"lastSeenCharacterIndex"];
    NSLog(@"Decoded lastSeenCharacterIndex as %ld", lastSeenCharacterIndex);
    [super decodeRestorableStateWithCoder:coder];
}

- (instancetype) initWithCoder:(NSCoder *)decoder {
    NSLog(@"GlkWinBufferView initWithCoder");
    self = [super initWithCoder:decoder];
    if (self) {
        lastSeenCharacterIndex = [decoder decodeIntegerForKey:@"lastSeenCharacterIndex"];
        NSLog(@"Decoded lastSeenCharacterIndex as %ld", lastSeenCharacterIndex);
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInteger:lastSeenCharacterIndex forKey:@"lastSeenCharacterIndex"];
    [super encodeWithCoder:encoder];
}

@end
