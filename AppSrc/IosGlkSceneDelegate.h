/* IosGlkSceneDelegate.h
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface IosGlkSceneDelegate : UIResponder <UIWindowSceneDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (readonly, strong) NSString *mainSceneActivityType;

@end

NS_ASSUME_NONNULL_END
