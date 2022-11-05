/* GlkUtilTypes.h: Miscellaneous objc classes
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <Foundation/Foundation.h>
#include "glk.h"

#ifdef DEBUG
#define DEBUG_PARANOID_ASSERT(cond, msg) NSAssert(cond, msg)
#else // DEBUG
#define DEBUG_PARANOID_ASSERT(cond, msg) do {} while (0)
#endif // DEBUG

@interface GlkTagString : NSObject {
	NSNumber *tag;
	NSString *str;
}

- (instancetype) initWithTag:(NSNumber *)tag text:(NSString *)str;

@property (nonatomic, strong) NSNumber *tag;
@property (nonatomic, strong) NSString *str;

@end


