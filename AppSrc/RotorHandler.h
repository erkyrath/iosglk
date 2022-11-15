//
//  RotorHandler.h
//  IosGlulxe
//
//  Created by Petter Sjölund on 2022-11-14.
//

#import <UIKit/UIKit.h>


@class GlkController;

NS_ASSUME_NONNULL_BEGIN

@interface RotorHandler : NSObject

//- (nullable UIAccessibilityCustomRotorItemResult *)textSearchResultForString:(NSString *)searchString fromRange:(UITextRange *)fromRange direction:(UIAccessibilityCustomRotorDirection)direction;
//
//- (nullable UIAccessibilityCustomRotorItemResult *)linksRotor:(UIAccessibilityCustomRotor *)rotor
//                           resultForSearchParameters:(UIAccessibilityCustomRotorSearchPredicate *)searchParameters;
//
//- (nullable UIAccessibilityCustomRotorItemResult *)glkWindowRotor:(UIAccessibilityCustomRotor *)rotor
//                               resultForSearchParameters:(UIAccessibilityCustomRotorSearchPredicate *)searchParameters;
//
//- (nullable UIAccessibilityCustomRotorItemResult *)commandHistoryRotor:(UIAccessibilityCustomRotor *)rotor
//                                    resultForSearchParameters:(UIAccessibilityCustomRotorSearchPredicate *)searchParameters;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray * _Nonnull createCustomRotors;

@end

NS_ASSUME_NONNULL_END
