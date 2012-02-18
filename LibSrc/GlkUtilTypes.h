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
	int pos;
}

@property (nonatomic, retain) NSString *str;
@property (nonatomic) glui32 style;
@property (nonatomic) int pos;

- (id) initWithText:(NSString *)str style:(glui32)style;
- (void) appendString:(NSString *)newstr;
- (void) freeze;

@end


@interface GlkVisualLine : NSObject {
	int vlinenum; /* This vline's index in the vlines array */
	int linenum; /* The raw line number that this vline belongs to */
	CGFloat ypos; /* Rendered top location */
	CGFloat height; /* Rendered height */
	CGFloat xstart; /* Left location of rendered text (left margin) */
	NSArray *arr; /* array of GlkVisualString */
}

@property (nonatomic) int vlinenum;
@property (nonatomic) int linenum;
@property (nonatomic) CGFloat ypos;
@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat xstart;
@property (nonatomic, retain) NSArray *arr;

- (id) initWithStrings:(NSArray *)strings;
- (CGFloat) bottom;

@end


@interface GlkVisualString : NSObject {
	NSString *str;
	glui32 style;
}

@property (nonatomic, retain) NSString *str;
@property (nonatomic) glui32 style;

- (id) initWithText:(NSString *)str style:(glui32)style;

@end


@interface GlkGridLine : NSObject {
	BOOL dirty;
	int width;
	glui32 *chars;
	glui32 *styles;
	int maxwidth;
}

@property (nonatomic) BOOL dirty;
@property (nonatomic) int width;
@property (nonatomic) glui32 *chars;
@property (nonatomic) glui32 *styles;

- (void) clear;

@end


@interface GlkTagString : NSObject {
	NSNumber *tag;
	NSString *str;
}

- (id) initWithTag:(NSNumber *)tag text:(NSString *)str;

@property (nonatomic, retain) NSNumber *tag;
@property (nonatomic, retain) NSString *str;

@end


