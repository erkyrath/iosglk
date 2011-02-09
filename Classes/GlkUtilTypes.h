/* GlkUtilTypes.h: Miscellaneous objc classes
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <Foundation/Foundation.h>
#include "glk.h"

typedef enum GlkStyledLineStatus_enum {
	linestat_Continue=0,
	linestat_NewLine=1,
	linestat_ClearPage=2
} GlkStyledLineStatus;

@interface GlkStyledLine : NSObject {
	GlkStyledLineStatus status;
	NSMutableArray *arr; /* array of GlkStyledString */
}

@property (nonatomic) GlkStyledLineStatus status;
@property (nonatomic, retain) NSMutableArray *arr;

- (id) initWithStatus:(GlkStyledLineStatus) status;

@end


@interface GlkStyledString : NSObject {
	NSString *str; /* may be NSMutableString */
	BOOL ismutable;
	glui32 style;
}

@property (nonatomic, retain) NSString *str;
@property (nonatomic) glui32 style;

- (id) initWithText:(NSString *)str style:(glui32)style;
- (void) appendString:(NSString *)newstr;
- (void) freeze;

@end
