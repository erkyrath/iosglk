//
//  GlkWindowViewUIState.m
//  iosglulxe
//
//  Created by Administrator on 2022-11-05.
//

#import "GlkWindowViewUIState.h"
#import "GlkWindowView.h"
#import "GlkWinBufferView.h"
#import "GlkWindowState.h"
#import "CmdTextField.h"

@implementation GlkWindowViewUIState

- (instancetype) initWithGlkWindowView:(GlkWindowView *)view {

    self = [super init];
    if (self && view) {
        UITextView *textview = view.subviews.firstObject;
        if (textview && [textview isKindOfClass:[UITextView class]]) {
            _selection = textview.selectedRange;

            if ([view isKindOfClass:[GlkWinBufferView class]]) {
                _lastSeenCharacterIndex = ((GlkWinBufferView *)view).lastSeenCharacterIndex;
                _contentOffsetY = textview.contentOffset.y;
                _scrolledToBottom = [(GlkWinBufferView *)view scrolledToBottom];
            }
        }

        GlkWindowState *state = view.winstate;
        if (state) {
            _tag = state.tag;
        }
        CmdTextField *input = view.inputfield;
        if (input) {
            _inputSelection = [GlkWindowViewUIState rangeFromTextRange:input.selectedTextRange textField:input];
            _inputText = input.text;
            _inputIsFirstResponder = input.isFirstResponder;
        }
    }
    return self;
}

+ (NSRange)rangeFromTextRange:(UITextRange *)textRange textField:(UITextField *)textField {
    UITextPosition* beginning = textField.beginningOfDocument;

    UITextPosition* selectionStart = textRange.start;
    UITextPosition* selectionEnd = textRange.end;

    const NSInteger location = [textField offsetFromPosition:beginning toPosition:selectionStart];
    const NSInteger length = [textField offsetFromPosition:selectionStart toPosition:selectionEnd];

    return NSMakeRange(location, length);
}

- (NSDictionary *) dictionaryFromState {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:6];
    if (_inputText)
        dict[@"inputText"] = _inputText;
    dict[@"lastSeenCharacterIndex"] = @(_lastSeenCharacterIndex);
    dict[@"scrolledToBottom"] = @(_scrolledToBottom);

    dict[@"selectionLoc"] = @(_selection.location);
    dict[@"selectionLen"] = @(_selection.length);

    dict[@"contentOffsetY"] = @(_contentOffsetY);

    dict[@"inputIsFirstResponder"] = @(_inputIsFirstResponder);
    dict[@"inputSelectionLoc"] = @(_inputSelection.location);
    dict[@"inputSelectionLen"] = @(_inputSelection.length);
    return dict;
}

@end
