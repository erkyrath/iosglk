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

+ (NSDictionary *) stateDictionaryFromWinView:(GlkWindowView *)view;

@end

NS_ASSUME_NONNULL_END
