//
//  GlkEventState.h
//  iosglulxe
//
//  Created by Administrator on 2022-10-22.
//

#import <Foundation/Foundation.h>
#include "glk.h"

NS_ASSUME_NONNULL_BEGIN

@interface GlkEventState : NSObject {
    glui32 type;
    glui32 ch;
    glui32 genval1;
    glui32 genval2;
    NSString *line;
    NSNumber *tag;
}

@property (nonatomic) glui32 type;
@property (nonatomic) glui32 ch;
@property (nonatomic) glui32 genval1;
@property (nonatomic) glui32 genval2;
@property (nonatomic, strong) NSString *line;
@property (nonatomic, strong) NSNumber *tag;

+ (GlkEventState *) charEvent:(glui32)ch inWindow:(NSNumber *)tag;
+ (GlkEventState *) lineEvent:(NSString *)line inWindow:(NSNumber *)tag;
+ (GlkEventState *) timerEvent;

@end

NS_ASSUME_NONNULL_END
