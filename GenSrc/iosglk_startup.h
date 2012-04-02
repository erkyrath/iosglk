
#ifdef __OBJC__
/* The following function can't be called from C, only from ObjC. */
@class NSString;
extern void iosglk_set_game_path(NSString *path);
#endif

extern void iosglk_startup_code(void);
