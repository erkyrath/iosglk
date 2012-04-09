/* Geometry.h: A size descriptor for a Glk window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <Foundation/Foundation.h>
#include "glk.h"

@class StyleSet;

@interface Geometry : NSObject {
	glui32 dir;
	glui32 division;
	BOOL hasborder;
	NSNumber *keytag;
	StyleSet *keystyleset;
	glui32 size;
	BOOL vertical;
	BOOL backward;
	
	NSNumber *child1tag;
	NSNumber *child2tag;
}

@property (nonatomic) glui32 dir;
@property (nonatomic) glui32 division;
@property (nonatomic) BOOL hasborder;
@property (nonatomic, retain) NSNumber *keytag;
@property (nonatomic, retain) StyleSet *keystyleset; // not serialized; styleset of key window
@property (nonatomic) glui32 size;
@property (nonatomic) BOOL vertical;
@property (nonatomic) BOOL backward;
@property (nonatomic, retain) NSNumber *child1tag;
@property (nonatomic, retain) NSNumber *child2tag;

- (void) computeDivision:(CGRect)box for1:(CGRect *)boxref1 for2:(CGRect *)boxref2;

@end
