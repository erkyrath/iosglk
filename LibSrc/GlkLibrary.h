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
@class GlkLibraryState;
@protocol IosGlkLibDelegate;

@interface GlkLibrary : NSObject {
	id <IosGlkLibDelegate> glkdelegate;
	
	NSMutableArray *windows; /* GlkWindow objects */
	NSMutableArray *streams; /* GlkStream objects */
	NSMutableArray *filerefs; /* GlkFileRef objects */
	
	BOOL vmexited;
	GlkWindow *rootwin;
	GlkStream *currentstr;
	CGRect bounds;
	BOOL geometrychanged;
	BOOL everythingchanged;
	
	id specialrequest;
	
	NSFileManager *filemanager; // for use in the VM thread
	NSCalendar *utccalendar; // ditto; allocated as-needed
	NSCalendar *localcalendar; // ditto; allocated as-needed
	
	NSInteger tagCounter;
	gidispatch_rock_t (*dispatch_register_obj)(void *obj, glui32 objclass);
	void (*dispatch_unregister_obj)(void *obj, glui32 objclass, gidispatch_rock_t objrock);
	gidispatch_rock_t (*dispatch_register_arr)(void *array, glui32 len, char *typecode);
	void (*dispatch_unregister_arr)(void *array, glui32 len, char *typecode, gidispatch_rock_t objrock);
}

@property (nonatomic, retain) id <IosGlkLibDelegate> glkdelegate;
@property (nonatomic, retain) NSMutableArray *windows;
@property (nonatomic, retain) NSMutableArray *streams;
@property (nonatomic, retain) NSMutableArray *filerefs;
@property (nonatomic) BOOL vmexited;
@property (nonatomic, retain) GlkWindow *rootwin;
@property (nonatomic, retain) GlkStream *currentstr;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic) BOOL geometrychanged;
@property (nonatomic) BOOL everythingchanged;
@property (nonatomic, retain) NSFileManager *filemanager;
@property (nonatomic, readonly) NSCalendar *utccalendar;
@property (nonatomic, readonly) NSCalendar *localcalendar;
@property (nonatomic, retain) id specialrequest;
@property (nonatomic) gidispatch_rock_t (*dispatch_register_obj)(void *obj, glui32 objclass);
@property (nonatomic) void (*dispatch_unregister_obj)(void *obj, glui32 objclass, gidispatch_rock_t objrock);
@property (nonatomic) gidispatch_rock_t (*dispatch_register_arr)(void *array, glui32 len, char *typecode);
@property (nonatomic) void (*dispatch_unregister_arr)(void *array, glui32 len, char *typecode, gidispatch_rock_t objrock);

+ (GlkLibrary *) singleton;
+ (void) strictWarning:(NSString *)msg;

- (NSString *) gameId;
- (NSNumber *) generateTag;
- (BOOL) setMetricsChanged:(BOOL)metricschanged bounds:(CGRect *)box;
- (GlkWindow *) windowForTag:(NSNumber *)tag;
- (void) dirtyAllData;

- (GlkLibraryState *) cloneState;

@end
