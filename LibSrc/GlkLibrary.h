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

@interface GlkLibrary : NSObject <NSSecureCoding> {
	id <IosGlkLibDelegate> glkdelegate;
	
	NSMutableArray *windows; /* GlkWindow objects */
	NSMutableArray *filerefs; /* GlkFileRef objects */
	
	BOOL vmexited;
	GlkWindow *rootwin;
	glui32 timerinterval; // milliseconds
	CGRect bounds;
	BOOL geometrychanged;
	BOOL metricschanged;
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
	long (*dispatch_locate_arr)(void *array, glui32 len, char *typecode, gidispatch_rock_t objrock, int *elemsizeref);
	gidispatch_rock_t (*dispatch_restore_arr)(long bufkey, glui32 len, char *typecode, void **arrayref);
}

@property (nonatomic, strong) id <IosGlkLibDelegate> glkdelegate;
@property (nonatomic, strong) NSMutableArray<GlkWindow *> *windows;
@property (nonatomic, strong) NSMutableArray<GlkStream *> *streams;
@property (nonatomic, strong) NSMutableArray<GlkFileRef *> *filerefs;
@property (nonatomic) BOOL vmexited;
@property (nonatomic, strong) GlkWindow *rootwin;
@property (nonatomic, weak) GlkStream *currentstr;
@property (nonatomic) glui32 timerinterval;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic) BOOL geometrychanged;
@property (nonatomic) BOOL metricschanged;
@property (nonatomic) BOOL everythingchanged;
@property (nonatomic, strong) NSFileManager *filemanager;
@property (weak, nonatomic, readonly) NSCalendar *utccalendar;
@property (weak, nonatomic, readonly) NSCalendar *localcalendar;
@property (nonatomic, readonly) NSInteger tagCounter;
@property (nonatomic, strong) id specialrequest;
@property (nonatomic) gidispatch_rock_t (*dispatch_register_obj)(void *obj, glui32 objclass);
@property (nonatomic) void (*dispatch_unregister_obj)(void *obj, glui32 objclass, gidispatch_rock_t objrock);
@property (nonatomic) gidispatch_rock_t (*dispatch_register_arr)(void *array, glui32 len, char *typecode);
@property (nonatomic) void (*dispatch_unregister_arr)(void *array, glui32 len, char *typecode, gidispatch_rock_t objrock);
@property (nonatomic) long (*dispatch_locate_arr)(void *array, glui32 len, char *typecode, gidispatch_rock_t objrock, int *elemsizeref);
@property (nonatomic) gidispatch_rock_t (*dispatch_restore_arr)(long bufkey, glui32 len, char *typecode, void **arrayref);

+ (GlkLibrary *) singleton;
+ (void) strictWarning:(NSString *)msg;

+ (void) setExtraArchiveHook:(void (*)(NSCoder *))hook;
+ (void) setExtraUnarchiveHook:(void (*)(NSCoder *))hook;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *gameId;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSNumber *generateTag;
- (void) setVMExited;
- (void) clearForRestart;
- (BOOL) setMetricsChanged:(BOOL)metricschanged bounds:(CGRect *)box;
- (GlkWindow *) windowForTag:(NSNumber *)tag;
- (GlkWindow *) windowForIntTag:(glui32)tag;
- (GlkStream *) streamForTag:(NSNumber *)tag;
- (GlkStream *) streamForIntTag:(glui32)tag;
- (GlkFileRef *) filerefForTag:(NSNumber *)tag;
- (GlkFileRef *) filerefForIntTag:(glui32)tag;
- (void) dirtyAllData;

- (void) sanityCheck;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) GlkLibraryState *cloneState;
- (void) updateFromLibrary:(GlkLibrary *)otherlib;

@end


@interface GlkExitException : NSException {
}
@end


