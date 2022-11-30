/* IosGlkTabBarControllerDelegate.m
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import "IosGlkViewController.h"
#import "IosGlkSceneDelegate.h"

#import "IosGlkTabBarControllerDelegate.h"

@implementation IosGlkTabBarControllerDelegate

- (void) tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewc {
    if (![viewc isKindOfClass:[UINavigationController class]])
        return;

    NSUserActivity *currentUserActivity = tabBarController.view.window.windowScene.userActivity;
    if (currentUserActivity == nil) {
        IosGlkSceneDelegate *sceneDelegate = (IosGlkSceneDelegate *)tabBarController.view.window.windowScene.delegate;
        if (sceneDelegate) {
            currentUserActivity = [[NSUserActivity alloc] initWithActivityType:[sceneDelegate mainSceneActivityType]];
        }
    }

    if (currentUserActivity) {
        [currentUserActivity addUserInfoEntriesFromDictionary:@{@"selectedTabIndex" : @(tabBarController.selectedIndex)}];
    }
}

@end
