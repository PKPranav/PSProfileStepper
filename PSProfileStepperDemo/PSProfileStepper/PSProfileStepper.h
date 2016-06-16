//
//  PSProfileStepper.h
//  PSProfileStepper
//
//  Created by Pramod Kumar Pranav on 5/25/16.
//  Copyright © 2016 AppStudioz. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface PSProfileStepper : UIControl

@property (nonatomic)  NSUInteger maxCount;
@property (nonatomic) IBInspectable NSUInteger index;
@property (nonatomic) IBInspectable NSUInteger circleCount;

@property (nonatomic) IBInspectable CGFloat lineHeight;
@property (nonatomic) IBInspectable CGFloat lineCircleRadius;
@property (nonatomic) IBInspectable CGFloat sliderCircleRadius;
@property (nonatomic) IBInspectable CGFloat labelFontSize;

@property (nonatomic, strong) IBInspectable UIColor *lineColor;
@property (nonatomic, strong) IBInspectable UIColor *sliderCircleColor;

@property (nonatomic, strong) IBInspectable UIColor *innerCircleColor;
@property (nonatomic, strong) IBInspectable UIColor *innerCircleNormalColor;

@property (nonatomic, strong) IBInspectable NSString *labelFontName;


- (void)setIndex:(NSUInteger)index animated:(BOOL)animated;

@end
