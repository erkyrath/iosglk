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

@class StyleSet;
@class GlkWinGridView;
@class StyledTextView;
@class GlkAccVisualLine;
@class GlkAccStyledLine;

typedef enum GlkStyledLineStatus_enum {
	linestat_Continue=0,
	linestat_NewLine=1,
	linestat_ClearPage=2
} GlkStyledLineStatus;

@interface GlkStyledLine : NSObject <NSSecureCoding> {
	int index; /* index in the window's lines array (but not necessarily zero-based) */
	GlkStyledLineStatus status;
	NSMutableArray *arr; /* array of GlkStyledString */

	NSString *concatline; /* the line contents, smushed together with no style information (cached value) */

	GlkAccStyledLine *accessel; /* the accessibility element (cached, or nil) */
}

@property (nonatomic) int index;
@property (nonatomic) GlkStyledLineStatus status;
@property (nonatomic, strong) NSMutableArray *arr;
@property (nonatomic, strong) NSString *concatline;
@property (nonatomic, strong) GlkAccStyledLine *accessel;

- (id) initWithIndex:(int)index;
- (id) initWithIndex:(int)index status:(GlkStyledLineStatus) status;
- (NSString *) concatLine;
- (NSString *) wordAtPos:(CGFloat)xpos styles:(StyleSet *)styleset;
- (NSString *) wordAtPos:(CGFloat)xpos styles:(StyleSet *)styleset inBox:(CGRect *)boxref;
- (GlkAccStyledLine *) accessElementInContainer:(GlkWinGridView *)container;

@end


@interface GlkStyledString : NSObject <NSSecureCoding> {
	NSString *str; /* may be NSMutableString */
	BOOL ismutable;
	glui32 style;
	int pos;
}

@property (nonatomic, strong) NSString *str;
@property (nonatomic) glui32 style;
@property (nonatomic) int pos;

- (id) initWithText:(NSString *)str style:(glui32)style;
- (void) appendString:(NSString *)newstr;
- (void) freeze;

@end


@interface GlkVisualLine : NSObject {
	StyleSet *styleset;
	int vlinenum; /* This vline's index in the vlines array */
	int linenum; /* The raw line number that this vline belongs to */
	CGFloat ypos; /* Rendered top location */
	CGFloat height; /* Rendered height */
	CGFloat xstart; /* Left location of rendered text (left margin) */
	NSArray *arr; /* array of GlkVisualString */
	
	NSString *concatline; /* the line contents, smushed together with no style information (cached value) */
	CGFloat *letterpos; /* array of letter positions (nth value is the left position of letter n, etc; last value is the right position of the last character). Length is concatline.length+1. (cached, malloced array of floats) */
	CGFloat right; /* Right edge of rendered text (cached value; -1 if not yet computed) */
	
	GlkAccVisualLine *accessel; /* the accessibility element (cached, or nil) */
}

@property (nonatomic) int vlinenum;
@property (nonatomic) int linenum;
@property (nonatomic) CGFloat ypos;
@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat xstart;
@property (nonatomic, strong) NSArray *arr;
@property (nonatomic, strong) NSString *concatline;
@property (nonatomic) CGFloat *letterpos;
@property (nonatomic, strong) StyleSet *styleset;
@property (nonatomic, strong) GlkAccVisualLine *accessel;

- (id) initWithStrings:(NSArray *)strings styles:(StyleSet *)styles;
- (CGFloat) bottom;
- (CGFloat) right;
- (NSString *) concatLine;
- (NSString *) wordAtPos:(CGFloat)xpos;
- (NSString *) wordAtPos:(CGFloat)xpos inBox:(CGRect *)boxref;
- (GlkAccVisualLine *) accessElementInContainer:(StyledTextView *)container;

@end


@interface GlkVisualString : NSObject {
	NSString *str;
	glui32 style;
}

@property (nonatomic, strong) NSString *str;
@property (nonatomic) glui32 style;

- (id) initWithText:(NSString *)str style:(glui32)style;

@end


@interface GlkGridLine : NSObject <NSSecureCoding> {
	BOOL dirty;
	int width;
	glui32 *chars; // malloced array (size maxwidth)
	glui32 *styles; // malloced array (size maxwidth)
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

@property (nonatomic, strong) NSNumber *tag;
@property (nonatomic, strong) NSString *str;

@end


