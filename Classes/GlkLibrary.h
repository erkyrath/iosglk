/* GlkLibrary.h: Library context object
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <Foundation/Foundation.h>
#include "glk.h"
#include "gi_dispa.h"

@class GlkWindow;
@class GlkStream;

@interface GlkLibrary : NSObject {
	NSMutableArray *windows; /* GlkWindow objects */
	NSMutableArray *streams; /* GlkStream objects */
	NSMutableArray *filerefs; /* GlkFileRef objects */
	
	GlkWindow *rootwin;
	GlkStream *currentstr;
	CGRect bounds;
	
	NSFileManager *filemanager; // for use in the VM thread
	
	NSInteger tagCounter;
	gidispatch_rock_t (*dispatch_register_obj)(void *obj, glui32 objclass);
	void (*dispatch_unregister_obj)(void *obj, glui32 objclass, gidispatch_rock_t objrock);
}

@property (nonatomic, retain) NSMutableArray *windows;
@property (nonatomic, retain) NSMutableArray *streams;
@property (nonatomic, retain) NSMutableArray *filerefs;
@property (nonatomic, retain) GlkWindow *rootwin;
@property (nonatomic, retain) GlkStream *currentstr;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, retain) NSFileManager *filemanager;
@property (nonatomic) gidispatch_rock_t (*dispatch_register_obj)(void *obj, glui32 objclass);
@property (nonatomic) void (*dispatch_unregister_obj)(void *obj, glui32 objclass, gidispatch_rock_t objrock);

+ (GlkLibrary *) singleton;
+ (void) strictWarning:(NSString *)msg;

- (NSNumber *) newTag;
- (BOOL) setMetrics:(CGRect)box;

@end
