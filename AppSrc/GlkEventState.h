/* GlkEventState.h
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

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
