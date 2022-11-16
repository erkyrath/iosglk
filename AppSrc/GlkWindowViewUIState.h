//
//  GlkWindowViewUIState.h
//  iosglulxe
//
//  Created by Administrator on 2022-11-05.
//

#import <Foundation/Foundation.h>
#include "glk.h"

NS_ASSUME_NONNULL_BEGIN

@class GlkWindowView;

@interface GlkWindowViewUIState : NSObject

@property (nonatomic, strong) NSNumber *tag;
@property (nonatomic, strong) NSString *inputText;
@property (nonatomic) NSUInteger lastSeenCharacterIndex;
@property (nonatomic) NSRange selection;
@property (nonatomic) BOOL inputIsFirstResponder;
@property (nonatomic) BOOL scrolledToBottom;
@property (nonatomic) NSRange inputSelection;
@property (nonatomic) CGFloat contentOffsetY;

- (instancetype) initWithGlkWindowView:(GlkWindowView *)view;
- (NSDictionary *) dictionaryFromState;

@end

NS_ASSUME_NONNULL_END
