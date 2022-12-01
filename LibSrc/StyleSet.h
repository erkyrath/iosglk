/* StyleSet.h: A set of font data for a Glk window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <Foundation/Foundation.h>
#include "glk.h"

typedef struct FontVariants_struct {
	UIFont *normal;
	UIFont *italic;
	UIFont *bold;
} FontVariants;

@interface StyleSet : NSObject

@property (nonatomic, readonly) NSMutableArray *fonts;
@property (nonatomic, readonly) NSMutableArray *colors;
@property (nonatomic) CGFloat leading; /* extra space below each line (uniform across all styles) */
@property (nonatomic) CGSize charbox; /* maximum size of a single rendered character (normal style) (including leading) */
@property (nonatomic, strong) UIColor *backgroundcolor; /* background color for window */
@property (nonatomic) UIEdgeInsets margins; /* margin widths around the text */
@property (nonatomic) CGSize margintotal; /* width = left+right; height = top+bottom */
@property NSArray<NSDictionary *> *gridattributes; /* array[style_NUMSTYLES] of attributes NSDictionary */
@property NSArray<NSDictionary *> *bufferattributes; /* array[style_NUMSTYLES] of attributes NSDictionary */


+ (StyleSet *) buildForWindowType:(glui32)wintype rock:(glui32)rock;
+ (FontVariants) fontVariantsForSize:(CGFloat)size name:(NSString *)first, ...;

- (void) completeForWindowType:(glui32)wintype;

@end
