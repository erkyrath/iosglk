//
//  GlkWindowViewUIState.m
//  iosglulxe
//
//  Created by Administrator on 2022-11-05.
//

#import "GlkWindowViewUIState.h"
#import "GlkWindowView.h"
#import "GlkWinBufferView.h"
#import "CmdTextField.h"

@implementation GlkWindowViewUIState

+ (NSRange)rangeFromTextRange:(UITextRange *)textRange textField:(UITextField *)textField {
    UITextPosition* beginning = textField.beginningOfDocument;

    UITextPosition* selectionStart = textRange.start;
    UITextPosition* selectionEnd = textRange.end;

    const NSInteger location = [textField offsetFromPosition:beginning toPosition:selectionStart];
    const NSInteger length = [textField offsetFromPosition:selectionStart toPosition:selectionEnd];

    return NSMakeRange(location, length);
}

+ (NSDictionary *) dictionaryFromState:(GlkWindowView *)view  {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:6];
    
    UIView *firstsubview = view.subviews[0];
    if (firstsubview && [firstsubview isKindOfClass:[UITextView class]]) {
        UITextView *textview = (UITextView *)firstsubview;
        NSRange selection = textview.selectedRange;
        dict[@"selectionLoc"] = @(selection.location);
        dict[@"selectionLen"] = @(selection.length);

        if ([view isKindOfClass:[GlkWinBufferView class]]) {
            dict[@"lastSeenCharacterIndex"] = @(((GlkWinBufferView *)view).lastSeenCharacterIndex);
            dict[@"contentOffsetY"] = @(textview.contentOffset.y);
            dict[@"scrolledToBottom"] = @([(GlkWinBufferView *)view scrolledToBottom]);
        }
    }

    CmdTextField *input = view.inputfield;
    if (input) {
        NSRange inputSelection = [GlkWindowViewUIState rangeFromTextRange:input.selectedTextRange textField:input];
        dict[@"inputText"] = input.text;
        dict[@"inputIsFirstResponder"] = @(input.isFirstResponder);
        dict[@"inputSelectionLoc"] = @(inputSelection.location);
        dict[@"inputSelectionLen"] = @(inputSelection.length);
    }

    return dict;
}

@end
