/* IosGlkTabBarControllerDelegate.h
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IosGlkTabBarControllerDelegate : NSObject <UITabBarControllerDelegate>

@property (nonatomic, weak) IBOutlet UITabBarController *tabBarController;

@end

NS_ASSUME_NONNULL_END
