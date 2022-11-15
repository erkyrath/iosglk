//
//  RotorHandler.m
//  IosGlulxe
//
//  Created by Petter Sjölund on 2022-11-14.
//

#import "RotorHandler.h"
#import "IosGlkAppDelegate.h"
#import "IosGlkViewController.h"
#import "GlkFrameView.h"

#import "GlkWindowView.h"
#import "GlkWinGridView.h"
#import "GlkWinBufferView.h"

#include "glk.h"


@implementation RotorHandler

//- (UIAccessibilityCustomRotorItemResult *)rotor:(UIAccessibilityCustomRotor *)rotor
//                      resultForSearchParameters:(UIAccessibilityCustomRotorSearch *)searchParameters  {
//// The name of the rotor is the title in the rotor item selection and what the user hears
//    UIAccessibilityCustomRotor *ratingRotor = [[UIAccessibilityCustomRotor alloc] initWithName:@"Rating Value" itemSearchBlock:^UIAccessibilityCustomRotorItemResult * _Nullable(UIAccessibilityCustomRotorSearchPredicate * _Nonnull predicate) {
//        <#code#>
//    }];
////                                               name: "Rating Value") { [weak self] predicate -> UIAccessibilityCustomRotorItemResult? in
////    guard let self = self else { return nil }
//
//    // When the user flicks up we want to increase the rating and down is used to decrease while keeping it within bounds
//    BOOL isFlickUp = (predicate.searchDirection == UIAccessibilityCustomRotorDirectionPrevious);
//    NSInteger delta = isFlickUp ? +1 : -1;
//    NSInteger rating = min(max(0, rating + delta), 4);
//
//    // Handles the UI updates to fill in the stars
//    self.setRating(value: rating)
//
//    // Notifies the system that the layout for the rating stack view changed
//    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.ratingStackView);
//
//    return [[UIAccessibilityCustomRotorItemResult alloc] initWithTargetElement:self.ratingStackView targetRange: nil];
//}

//- (UIAccessibilityCustomRotorItemResult *)rotor:(UIAccessibilityCustomRotor *)rotor
//                      resultForSearchParameters:(UIAccessibilityCustomRotorSearchPredicate *)searchParameters  {
//
//    if (rotor.systemRotorType == UIAccessibilityCustomSystemRotorTypeNone) {
//        UIAccessibilityCustomRotorItemResult *currentItemResult = searchParameters.currentItem;
//        return [self textSearchResultForString:searchParameters.name
//                                     fromRange:currentItemResult.targetRange
//                                     direction:searchParameters.searchDirection];
//    } else if ([rotor.name isEqualToString:NSLocalizedString(@"Command history", nil)]) {
//        return [self commandHistoryRotor:rotor resultForSearchParameters:searchParameters];
//    } else if ([rotor.name isEqualToString:NSLocalizedString(@"Game windows", nil)]) {
//        return [self glkWindowRotor:rotor resultForSearchParameters:searchParameters];
//    } else if (rotor.systemRotorType == UIAccessibilityCustomSystemRotorTypeLink) {
//        return [self linksRotor:rotor resultForSearchParameters:searchParameters];
//    }
//
//    return nil;
//}

//- (UIAccessibilityCustomRotorItemResult *)textSearchResultForString:(NSString *)searchString fromRange:(UITextRange *)fromRange direction:(UIAccessibilityCustomRotorDirection)direction {
//
//    UIAccessibilityCustomRotorItemResult *searchResult = nil;
//
//    UITextView *bestMatch = nil;
//    NSRange bestMatchRange;
//
//    if (searchString.length) {
//        BOOL searchFound = NO;
//        GlkController *glkctl = _glkctl;
//        NSArray<GlkWindow *> *allWindows = glkctl.gwindows.allValues;
//        for (GlkWindow *view in allWindows) {
//            if (![view isKindOfClass:[GlkGraphicsWindow class]]) {
//                NSString *contentString = ((GlkTextGridWindow *)view).textview.string;
//
//                NSRange resultRange = [contentString rangeOfString:searchString options:NSCaseInsensitiveSearch range:NSMakeRange(0, contentString.length) locale:nil];
//
//                if (resultRange.location == NSNotFound)
//                    continue;
//
//                if (direction == UIAccessibilityCustomRotorDirectionPrevious) {
//                    searchFound = (resultRange.location < fromRange.location);
//                } else if (direction == UIAccessibilityCustomRotorDirectionNext) {
//                    searchFound = (resultRange.location >= NSMaxRange(fromRange));
//                }
//                if (searchFound) {
//                    searchResult = [[UIAccessibilityCustomRotorItemResult alloc] initWithTargetElement:((GlkTextGridWindow *)view).textview];
//                    searchResult.targetRange = resultRange;
//                    return searchResult;
//                }
//
//                bestMatchRange = resultRange;
//                bestMatch = ((GlkTextGridWindow *)view).textview;
//            }
//        }
//    }
//    if (bestMatch) {
//        searchResult = [[UIAccessibilityCustomRotorItemResult alloc] initWithTargetElement:bestMatch];
//        searchResult.targetRange = bestMatchRange;
//    }
//    return searchResult;
//}

//- (UIAccessibilityCustomRotorItemResult *)glkWindowRotor:(UIAccessibilityCustomRotor *)rotor
//                               resultForSearchParameters:(UIAccessibilityCustomRotorSearchPredicate *)searchParameters {
//    UIAccessibilityCustomRotorItemResult *searchResult = nil;
//
////    [[UIAccessibilityCustomRotor alloc] initWithName:@"Rating Value" itemSearchBlock:^UIAccessibilityCustomRotorItemResult * _Nullable(UIAccessibilityCustomRotorSearchPredicate * _Nonnull predicate) {
//////        <#code#>
//////    }];
//
//    UIAccessibilityCustomRotorItemResult *currentItemResult = searchParameters.currentItem;
//    UIAccessibilityCustomRotorDirection direction = searchParameters.searchDirection;
//    NSString *filterText = searchParameters.filterString;
//
//    NSMutableArray *children = [[NSMutableArray alloc] init];
//    NSMutableArray *strings = [[NSMutableArray alloc] init];
//
//    GlkController *glkctl = _glkctl;
//    NSArray *allWindows = glkctl.gwindows.allValues;
//
//    if (glkctl.quoteBoxes.count)
//        allWindows = [allWindows arrayByAddingObject:glkctl.quoteBoxes.lastObject];
//
//    allWindows = [allWindows sortedArrayUsingComparator:
//                  ^NSComparisonResult(NSView * obj1, NSView * obj2){
//        CGFloat y1 = obj1.frame.origin.y;
//        CGFloat y2 = obj2.frame.origin.y;
//        if (y1 > y2) {
//            return (NSComparisonResult)NSOrderedDescending;
//        }
//        if (y1 < y2) {
//            return (NSComparisonResult)NSOrderedAscending;
//        }
//        return (NSComparisonResult)NSOrderedSame;
//    }];
//
//    NSString *charSetString = @"\u00A0 >\n_";
//    NSCharacterSet *charset = [NSCharacterSet characterSetWithCharactersInString:charSetString];
//
//    for (GlkWindow *win in allWindows) {
//        if (![win isKindOfClass:[GlkGraphicsWindow class]]) {
//            GlkTextBufferWindow *bufWin = (GlkTextBufferWindow *)win;
//            NSTextView *textview = bufWin.textview;
//            NSString *string = textview.string;
//            if ([win isKindOfClass:[GlkTextBufferWindow class]]) {
//                if (bufWin.moveRanges.count) {
//                    NSRange range = bufWin.moveRanges.lastObject.rangeValue;
//                    string = [string substringFromIndex:range.location];
//                }
//            }
//
//            if (string.length && (filterText.length == 0 || [string localizedCaseInsensitiveContainsString:filterText])) {
//                [children addObject:textview];
//                string = [string stringByTrimmingCharactersInSet:charset];
//                [strings addObject:string.copy];
//            }
//        } else {
//            NSString *string = win.accessibilityRoleDescription;
//            if (string.length && win.images.count && (filterText.length == 0 || [string localizedCaseInsensitiveContainsString:filterText])) {
//                [children addObject:win];
//                [strings addObject:string.copy];
//            }
//        }
//    }
//
//    if (!children.count)
//        return nil;
//
//    NSUInteger currentItemIndex = [children indexOfObject:currentItemResult.targetElement];
//
//    if (currentItemIndex == NSNotFound) {
//        // Find the start or end element.
//        if (direction == UIAccessibilityCustomRotorDirectionNext) {
//            currentItemIndex = 0;
//        } else if (direction == UIAccessibilityCustomRotorDirectionPrevious) {
//            currentItemIndex = children.count - 1;
//        }
//    } else {
//        if (direction == UIAccessibilityCustomRotorDirectionPrevious) {
//            if (currentItemIndex == 0) {
//                currentItemIndex = NSNotFound;
//            } else {
//                currentItemIndex--;
//            }
//        } else if (direction == UIAccessibilityCustomRotorDirectionNext) {
//            if (currentItemIndex == children.count - 1) {
//                currentItemIndex = NSNotFound;
//            } else {
//                currentItemIndex++;
//            }
//        }
//    }
//
//    if (currentItemIndex == NSNotFound) {
//        return nil;
//    }
//
//    NSTextView *targetWindow = children[currentItemIndex];
//
//    if (targetWindow) {
//        searchResult = [[UIAccessibilityCustomRotorItemResult alloc] initWithTargetElement: targetWindow];
//        searchResult.customLabel = strings[currentItemIndex];
//        if (![targetWindow isKindOfClass:[GlkGraphicsWindow class]]) {
//            NSRange allText = NSMakeRange(0, targetWindow.string.length);
//            NSArray<NSValue *> *moveRanges = ((GlkWindow *)targetWindow.delegate).moveRanges;
//            if (moveRanges && moveRanges.count) {
//                if ([targetWindow.delegate isKindOfClass:[GlkTextBufferWindow class]])
//                    [(GlkTextBufferWindow *)targetWindow.delegate forceLayout];
//                NSRange range = moveRanges.lastObject.rangeValue;
//                searchResult.targetRange = NSIntersectionRange(allText, range);
//            } else searchResult.targetRange = allText;
//        }
//    }
//    return searchResult;
//}
//


- (NSArray *)createCustomRotors {
    NSMutableArray *rotorsArray = [[NSMutableArray alloc] init];
    
    //        BOOL hasLinks = NO;
    //        BOOL hasImages = NO;
    
    IosGlkAppDelegate *appdel = [IosGlkAppDelegate singleton];
    IosGlkViewController *glkviewc = appdel.glkviewc;
    GlkFrameView *frameview  = glkviewc.frameview;
    
    //#pragma mark text search rotor
    //        // Create the text search rotor.
    //        UIAccessibilityCustomRotor *textSearchRotor = [[UIAccessibilityCustomRotor alloc] initWithSystemType:UIAccessibilityCustomSystemRotorTypeNone itemSearchBlock:^UIAccessibilityCustomRotorItemResult * _Nullable(UIAccessibilityCustomRotorSearchPredicate * _Nonnull predicate) {
    //
    //                UIAccessibilityCustomRotorItemResult *currentItemResult =  predicate.currentItem;
    //                return [self textSearchResultForString:searchParameters.name
    //                                             fromRange:currentItemResult.targetRange
    //                                             direction:searchParameters.searchDirection];
    //            } else if ([rotor.name isEqualToString:NSLocalizedString(@"Command history", nil)]) {
    //                return [self commandHistoryRotor:rotor resultForSearchParameters:searchParameters];
    //            } else if ([rotor.name isEqualToString:NSLocalizedString(@"Game windows", nil)]) {
    //                return [self glkWindowRotor:rotor resultForSearchParameters:searchParameters];
    //            } else if (rotor.systemRotorType == UIAccessibilityCustomSystemRotorTypeLink) {
    //                return [self linksRotor:rotor resultForSearchParameters:searchParameters];
    //            }
    //
    //            return nil;
    //        }];
    //
    //        [rotorsArray addObject:textSearchRotor];
    
#pragma mark previous moves rotor
    
    // Create the previous moves rotor
    if ([frameview largestWithMoves]) {
        UIAccessibilityCustomRotor *commandHistoryRotor = [[UIAccessibilityCustomRotor alloc] initWithName:@"Previous Moves" itemSearchBlock:^UIAccessibilityCustomRotorItemResult * _Nullable(UIAccessibilityCustomRotorSearchPredicate * _Nonnull predicate) {
            UIAccessibilityCustomRotorItemResult *searchResult = nil;
            
            UIAccessibilityCustomRotorDirection direction = predicate.searchDirection;
            UITextRange *currentRange = predicate.currentItem.targetRange;
            
            
            GlkWinBufferView *largest = [frameview largestWithMoves];
            if (!largest)
                return nil;
            
            UITextView *textview = largest.textview;
            
            NSArray *children = [largest.moveRanges reverseObjectEnumerator].allObjects;
            
            if (children.count > 50)
                children = [children subarrayWithRange:NSMakeRange(0, 50)];
            NSMutableArray *strings = [[NSMutableArray alloc] initWithCapacity:children.count];
            NSMutableArray *mutableChildren = [[NSMutableArray alloc] initWithCapacity:children.count];
            
            for (UITextRange *range in children) {
                NSString *string = [textview textInRange:range];
                [strings addObject:string];
                [mutableChildren addObject:range];
            }
            
            if (!mutableChildren.count)
                return nil;
            
            children = mutableChildren;
            
            NSUInteger currentItemIndex = [children indexOfObject:currentRange];
            
            if (currentItemIndex == NSNotFound) {
                // Find the start or end element.
                if (direction == UIAccessibilityCustomRotorDirectionNext) {
                    currentItemIndex = 0;
                } else if (direction == UIAccessibilityCustomRotorDirectionPrevious) {
                    currentItemIndex = children.count - 1;
                }
            } else {
                if (direction == UIAccessibilityCustomRotorDirectionPrevious) {
                    if (currentItemIndex == 0) {
                        currentItemIndex = NSNotFound;
                    } else {
                        currentItemIndex--;
                    }
                } else if (direction == UIAccessibilityCustomRotorDirectionNext) {
                    if (currentItemIndex == children.count - 1) {
                        currentItemIndex = NSNotFound;
                    } else {
                        currentItemIndex++;
                    }
                }
            }
            
            if (currentItemIndex == NSNotFound) {
                return nil;
            }
            
            UITextRange *textRange = children[currentItemIndex];
            
            if (textRange) {
                searchResult = [[UIAccessibilityCustomRotorItemResult alloc] initWithTargetElement:textview targetRange:textRange];
                // By adding a custom label, all ranges are reliably listed in the rotor
                NSString *charSetString = @"\u00A0 >\n_";
                NSCharacterSet *charset = [NSCharacterSet characterSetWithCharactersInString:charSetString];
                NSString *string = strings[currentItemIndex];
                string = [string stringByTrimmingCharactersInSet:charset];
                {
                    // Strip command line if the speak command setting is off
                    //                        if (!_glkctl.theme.vOSpeakCommand)
                    //                        {
                    NSUInteger promptIndex = [textview offsetFromPosition:textview.beginningOfDocument toPosition:searchResult.targetRange.start];
                    if (promptIndex != 0)
                        promptIndex--;
                    if ([textview.text characterAtIndex:promptIndex] == '>' || (promptIndex > 0 && [textview.text characterAtIndex:promptIndex - 1] == '>')) {
                        NSRange foundRange = [string rangeOfString:@"\n"];
                        if (foundRange.location != NSNotFound)
                        {
                            string = [string substringFromIndex:foundRange.location];
                        }
                    }
                    //                        }
                }
                searchResult.accessibilityLabel = string;
            }
            
            return searchResult;
        }];
        if (commandHistoryRotor) {
            NSLog(@"Adding commandHistoryRotor");
            [rotorsArray addObject:commandHistoryRotor];
        }
    }
    
#pragma mark Glk windows rotor
    
    // Create the Glk windows rotor
    if (frameview.windowviews.count) {
        UIAccessibilityCustomRotor *glkWindowRotor = [[UIAccessibilityCustomRotor alloc] initWithName:@"Game windows" itemSearchBlock:^UIAccessibilityCustomRotorItemResult * _Nullable(UIAccessibilityCustomRotorSearchPredicate * _Nonnull predicate) {
            UIAccessibilityCustomRotorItemResult *searchResult = nil;
            
            UIAccessibilityCustomRotorItemResult *currentItemResult = predicate.currentItem;
            UIAccessibilityCustomRotorDirection direction = predicate.searchDirection;
            
            NSMutableArray *children = [[NSMutableArray alloc] init];
            NSMutableArray *strings = [[NSMutableArray alloc] init];
            
            NSArray *allWindows = frameview.windowviews.allValues;
            
            allWindows = [allWindows sortedArrayUsingComparator:
                          ^NSComparisonResult(UIView * obj1, UIView * obj2){
                CGFloat y1 = obj1.frame.origin.y;
                CGFloat y2 = obj2.frame.origin.y;
                if (y1 > y2) {
                    return (NSComparisonResult)NSOrderedDescending;
                }
                if (y1 < y2) {
                    return (NSComparisonResult)NSOrderedAscending;
                }
                return (NSComparisonResult)NSOrderedSame;
            }];
            
            NSString *charSetString = @"\u00a0 >\n_";
            NSCharacterSet *charset = [NSCharacterSet characterSetWithCharactersInString:charSetString];
            GlkWinBufferView *bufWin = nil;
            for (GlkWindowView *win in allWindows) {
                bufWin = (GlkWinBufferView *)win;
                NSString *string = @"";
                if ([win isKindOfClass:[GlkWinBufferView class]]) {
                    if (bufWin.moveRanges.count) {
                        string = [bufWin.textview textInRange:bufWin.moveRanges.lastObject];
                    }
                }
                
                [children addObject:bufWin.textview];
                string = [string stringByTrimmingCharactersInSet:charset];
                [strings addObject:string.copy];
            }
            
            if (!children.count)
                return nil;
            
            NSUInteger currentItemIndex = [children indexOfObject:currentItemResult.targetElement];
            
            if (currentItemIndex == NSNotFound) {
                // Find the start or end element.
                if (direction == UIAccessibilityCustomRotorDirectionNext) {
                    currentItemIndex = 0;
                } else if (direction == UIAccessibilityCustomRotorDirectionPrevious) {
                    currentItemIndex = children.count - 1;
                }
            } else {
                if (direction == UIAccessibilityCustomRotorDirectionPrevious) {
                    if (currentItemIndex == 0) {
                        currentItemIndex = NSNotFound;
                    } else {
                        currentItemIndex--;
                    }
                } else if (direction == UIAccessibilityCustomRotorDirectionNext) {
                    if (currentItemIndex == children.count - 1) {
                        currentItemIndex = NSNotFound;
                    } else {
                        currentItemIndex++;
                    }
                }
            }
            
            if (currentItemIndex == NSNotFound) {
                return nil;
            }
            
            UITextView *targetWindow = children[currentItemIndex];
            
            if (targetWindow) {
                searchResult = [[UIAccessibilityCustomRotorItemResult alloc] initWithTargetElement:targetWindow targetRange:bufWin.moveRanges.lastObject];
                searchResult.accessibilityLabel = strings[currentItemIndex];
                NSArray<UITextRange *> *moveRanges = bufWin.moveRanges;
                if (moveRanges && moveRanges.count)
                    searchResult.targetRange = moveRanges.lastObject;
                else searchResult.targetRange = [targetWindow textRangeFromPosition:targetWindow.beginningOfDocument toPosition:targetWindow.endOfDocument];
            }
            return searchResult;
        }];
        if (glkWindowRotor) {
            NSLog(@"Adding glkWindowRotor");
            [rotorsArray addObject:glkWindowRotor];
        }
    }
    return rotorsArray;
}

@end
