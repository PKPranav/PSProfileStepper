//
//  PSProfileStepper.m
//  PSProfileStepper
//
//  Created by Pramod Kumar Pranav on 5/25/16.
//  Copyright © 2016 AppStudioz. All rights reserved.
//

#import "PSProfileStepper.h"

#define GEN_SETTER(PROPERTY, TYPE, SETTER, UPDATER) \
- (void)SETTER:(TYPE)PROPERTY { \
if (_##PROPERTY != PROPERTY) { \
_##PROPERTY = PROPERTY; \
UPDATER \
[self setNeedsLayout]; \
} \
}

@interface PSTextLayer : CATextLayer
@end
@implementation PSTextLayer

-(id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}
-(id)initWithLayer:(id)layer
{
    self = [super initWithLayer:layer];
    if (self) {
    }
    return self;
}
-(id)initWithCoder:(id)coder
{
    self = [super initWithCoder:coder];
    if (self) {
    }
    return self;
}
-(void)drawInContext:(CGContextRef)ctx
{
    CGFloat height = self.bounds.size.height;
    CGFloat fontSize = self.fontSize;
    CGFloat yDiff = (height-fontSize)/2 - fontSize/10;
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, 0.0, yDiff);
    [super drawInContext:ctx];
    CGContextRestoreGState(ctx);
}
@end

static NSString * const kTrackAnimation = @"kTrackAnimation";

typedef void (^withoutAnimationBlock)(void);
void withoutCAAnimation(withoutAnimationBlock code)
{
    [CATransaction begin];
    [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    code();
    [CATransaction commit];
}

@interface PSProfileStepper ()
{
    CAShapeLayer *_lineLayer;
    CAShapeLayer *_sliderCircleLayer;
    
    NSMutableArray <CAShapeLayer *> *_lineCirclesArray;
    NSMutableArray <PSTextLayer *> *_circleLabelsArray;
    
    BOOL animateLayouts;
    
    CGFloat maxRadius;
    CGFloat diff;
    
    CGPoint startTouchPosition;
    CGPoint startSliderPosition;
}


@end

@implementation PSProfileStepper

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initialSetup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialSetup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _maxCount           = 97;
        [self makeDefaultValues];
        [self addLayers];
    }
    return self;
}

- (void)makeDefaultValues {
    
    if(_labelFontName.length == 0)
    {
        _labelFontName     = @"Helvetica-Bold";
    }
    //Other properties...
}


- (void)addLayers
{
    _lineCirclesArray = [[NSMutableArray alloc] init];
    _circleLabelsArray = [[NSMutableArray alloc] init];
    
    _lineLayer = [CAShapeLayer layer];
    _sliderCircleLayer = [CAShapeLayer layer];
    
    [self.layer addSublayer:_lineLayer];
    [self.layer addSublayer:_sliderCircleLayer];
}

- (void)initialSetup
{
    [self addLayers];
    
    
    _maxCount           = 97;
    _circleCount        = 2;
    _index              = 2;
    _lineHeight        = 4.f;
    _lineCircleRadius  = 5.f;
    _sliderCircleRadius = 12.5f;
    _labelFontSize      = 10.f;
    _labelFontName      = @"Helvetica-Bold";
    _lineColor         = [UIColor colorWithWhite:0.41f alpha:1.f];
    _sliderCircleColor  = [UIColor whiteColor];
   
    
    [self setNeedsLayout];
}

- (void)layoutLayersAnimated:(BOOL)animated
{
    NSInteger indexDiff = fabsf(roundf([self indexCalculate]) - self.index);
    BOOL left = (roundf([self indexCalculate]) - self.index) < 0;
    
    CGRect contentFrame = CGRectMake(maxRadius, 0.f, self.bounds.size.width - 2 * maxRadius, self.bounds.size.height);
    
    CGFloat stepWidth       = contentFrame.size.width / (self.maxCount - 1);
    CGFloat circleFrameSide = self.lineCircleRadius * 2.f;
    CGFloat sliderDiameter  = self.sliderCircleRadius * 2.f;
    CGFloat sliderFrameSide = fmaxf(self.sliderCircleRadius * 2.f, 44.f);
    CGRect  sliderDrawRect  = CGRectMake((sliderFrameSide - sliderDiameter) / 2.f, (sliderFrameSide - sliderDiameter) / 2.f, sliderDiameter, sliderDiameter);
    
    CGPoint oldPosition = _sliderCircleLayer.position;
    CGPathRef oldPath   = _lineLayer.path;
    
    if (!animated) {
        [CATransaction begin];
        [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    }
    
    _sliderCircleLayer.frame     = CGRectMake(0.f, 0.f, sliderFrameSide, sliderFrameSide);
    _sliderCircleLayer.path      = [UIBezierPath bezierPathWithRoundedRect:sliderDrawRect cornerRadius:sliderFrameSide / 2].CGPath;
    _sliderCircleLayer.fillColor = [self.sliderCircleColor CGColor];
    _sliderCircleLayer.position  = CGPointMake(contentFrame.origin.x + stepWidth * self.index , (contentFrame.size.height ) / 2.f);
    
    if (animated) {
        CABasicAnimation *basicSliderAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        basicSliderAnimation.duration = [CATransaction animationDuration];
        basicSliderAnimation.fromValue = [NSValue valueWithCGPoint:(oldPosition)];
        [_sliderCircleLayer addAnimation:basicSliderAnimation forKey:@"position"];
    }
    
    _lineLayer.frame = CGRectMake(contentFrame.origin.x,
                                   (contentFrame.size.height - self.lineHeight) / 2.f,
                                   contentFrame.size.width,
                                   self.lineHeight);
    _lineLayer.path            = [self fillingPath];
    _lineLayer.backgroundColor = [self.lineColor CGColor];
    _lineLayer.fillColor       = [self.tintColor CGColor];
    
    if (animated) {
        CABasicAnimation *basicTrackAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
        basicTrackAnimation.duration = [CATransaction animationDuration];
        basicTrackAnimation.fromValue = (__bridge id _Nullable)(oldPath);
        [_lineLayer addAnimation:basicTrackAnimation forKey:@"path"];
    }
    
    
    if (_lineCirclesArray.count > self.maxCount) {
        
        for (NSUInteger i = self.maxCount; i < _lineCirclesArray.count; i++) {
            [_lineCirclesArray[i] removeFromSuperlayer];
        }
        
        _lineCirclesArray = [[_lineCirclesArray subarrayWithRange:NSMakeRange(0, self.maxCount)] mutableCopy];
    }
    
    if (_circleLabelsArray.count > self.maxCount) {
        
        for (NSUInteger i = self.maxCount; i < _circleLabelsArray.count; i++) {
            [_circleLabelsArray[i] removeFromSuperlayer];
        }
        
        _circleLabelsArray = [[_circleLabelsArray subarrayWithRange:NSMakeRange(0, self.maxCount)] mutableCopy];
    }
    
    
    
    NSTimeInterval animationTimeDiff = left ? [CATransaction animationDuration] / indexDiff : -[CATransaction animationDuration] / indexDiff;
    NSTimeInterval animationTime = left ?  animationTimeDiff : [CATransaction animationDuration] + animationTimeDiff;
    int steperCount=0;
    NSLog(@"Cccc:::%lu",(_circleCount-1));
    for (NSUInteger i = 0; i < self.maxCount; i++) {
        
        CAShapeLayer *lineCircle;
        PSTextLayer *circleLabel;
        
        if (i < _lineCirclesArray.count) {
            lineCircle = _lineCirclesArray[i];
        } else {
            lineCircle       = [CAShapeLayer layer];
            
            if (i%(self.maxCount/(_circleCount-1)) == 0 )
            {
                [self.layer addSublayer:lineCircle];
            }
            
            [_lineCirclesArray addObject:lineCircle];
        }
        
        if (i < _circleLabelsArray.count) {
            circleLabel = _circleLabelsArray[i];
        } else {
            circleLabel       = [PSTextLayer layer];
            [circleLabel setFont:(__bridge CFTypeRef _Nullable)(_labelFontName)];
            [circleLabel setFontSize:_labelFontSize];
            [circleLabel setAlignmentMode:kCAAlignmentCenter];
            circleLabel.backgroundColor = [UIColor clearColor].CGColor;
            if (i%(self.maxCount/(_circleCount-1)) == 0 )
            {
                [self.layer addSublayer:circleLabel];
                [circleLabel setString:[NSString stringWithFormat:@"%d",steperCount++]];
            }
            
            [_circleLabelsArray addObject:circleLabel];
        }
        
        lineCircle.frame    = CGRectMake(0.f, 0.f, circleFrameSide, circleFrameSide);
        lineCircle.path     = [UIBezierPath bezierPathWithRoundedRect:lineCircle.bounds cornerRadius:circleFrameSide / 2].CGPath;
        lineCircle.position = CGPointMake(contentFrame.origin.x + stepWidth * i, contentFrame.size.height / 2.f);
        
        circleLabel.frame    = CGRectMake(0.f, 0.f, circleFrameSide, circleFrameSide);
        circleLabel.position = CGPointMake(contentFrame.origin.x + stepWidth * i, contentFrame.size.height / 2.f);
        //lineCircle fillColor
        if (animated) {
            CGColorRef newColor = [self lineInnerCircleColor:lineCircle];
            CGColorRef oldColor = lineCircle.fillColor;
            
            if (!CGColorEqualToColor(newColor, lineCircle.fillColor)) {
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(animationTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    lineCircle.fillColor = newColor;
                    
                    CABasicAnimation *basicTrackCircleAnimation = [CABasicAnimation animationWithKeyPath:@"fillColor"];
                    basicTrackCircleAnimation.duration = [CATransaction animationDuration] / 2.f;
                    basicTrackCircleAnimation.fromValue = (__bridge id _Nullable)(oldColor);
                    [lineCircle addAnimation:basicTrackCircleAnimation forKey:@"fillColor"];
                });
                
                animationTime += animationTimeDiff;
            }
        } else {
            lineCircle.fillColor = [self lineInnerCircleColor:lineCircle];
        }
        //lineCircle strokeColor
        if (animated) {
            CGColorRef newColorInner = [self lineCircleColor:lineCircle];
            CGColorRef oldColorInner = lineCircle.strokeColor;
            
            if (!CGColorEqualToColor(newColorInner, lineCircle.strokeColor)) {
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(animationTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    lineCircle.strokeColor = newColorInner;
                    lineCircle.lineWidth = 2.0f;
                    
                    CABasicAnimation *basicTrackCircleInnerAnimation = [CABasicAnimation animationWithKeyPath:@"strokeColor"];
                    basicTrackCircleInnerAnimation.duration = [CATransaction animationDuration] / 2.f;
                    basicTrackCircleInnerAnimation.fromValue = (__bridge id _Nullable)(oldColorInner);
                    [lineCircle addAnimation:basicTrackCircleInnerAnimation forKey:@"strokeColor"];
                });
                
                animationTime += animationTimeDiff;
            }
        } else {
            lineCircle.strokeColor = [self lineCircleColor:lineCircle];
            lineCircle.lineWidth = 2.0f;
        }
        
        //TrackLabel foregroundColor
        if (animated) {
            CGColorRef newColorLabel = [self circleLabelColor:circleLabel];
            CGColorRef oldColorLabel = circleLabel.foregroundColor;
            
            if (!CGColorEqualToColor(newColorLabel, circleLabel.foregroundColor)) {
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(animationTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    circleLabel.foregroundColor = newColorLabel;
                    
                    CABasicAnimation *basicTrackLabelAnimation = [CABasicAnimation animationWithKeyPath:@"foregroundColor"];
                    basicTrackLabelAnimation.duration = [CATransaction animationDuration] / 2.f;
                    basicTrackLabelAnimation.fromValue = (__bridge id _Nullable)(oldColorLabel);
                    [circleLabel addAnimation:basicTrackLabelAnimation forKey:@"foregroundColor"];
                });
                
                animationTime += animationTimeDiff;
            }
        } else {
            circleLabel.foregroundColor = [self circleLabelColor:circleLabel];
            ;
            
        }
        
    }
    
    if (!animated) {
        [CATransaction commit];
    }
    
    [_sliderCircleLayer removeFromSuperlayer];
    [self.layer addSublayer:_sliderCircleLayer];
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self layoutLayersAnimated:animateLayouts];
    animateLayouts = NO;
}

#pragma mark - Helpers Method
/**
 Calculate distance from lineCircle center to point where circle cross line.
 */
- (void)updateDiff
{
    diff = sqrtf(fmaxf(0.f, powf(self.lineCircleRadius, 2.f) - pow(self.lineHeight / 2.f, 2.f)));
}

- (void)updateMaxRadius
{
    maxRadius = fmaxf(self.lineCircleRadius, self.sliderCircleRadius);
}

- (void)updateIndex
{
    if (_index > (_maxCount - 1)) {
        _index = _maxCount - 1;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (CGPathRef)fillingPath
{
    CGRect fillRect     = _lineLayer.bounds;
    fillRect.size.width = self.sliderPosition;
    
    return [UIBezierPath bezierPathWithRect:fillRect].CGPath;
}

- (CGFloat)sliderPosition
{
    return _sliderCircleLayer.position.x - maxRadius;
}

- (CGFloat)lineCirclePosition:(CAShapeLayer *)lineCircle
{
    return lineCircle.position.x - maxRadius;
}

- (CGFloat)circleLabelPosition:(PSTextLayer *)circleLabel
{
    return circleLabel.position.x - maxRadius;
}


- (CGFloat)indexCalculate
{
    return self.sliderPosition / (_lineLayer.bounds.size.width / (self.maxCount - 1));
}

- (CGColorRef)lineCircleColor:(CAShapeLayer *)lineCircle
{
    return self.sliderPosition + diff >= [self lineCirclePosition:lineCircle] ? self.tintColor.CGColor : self.lineColor.CGColor;
}

- (CGColorRef)circleLabelColor:(PSTextLayer *)circleLabel
{
    return self.sliderPosition + diff >= [self circleLabelPosition:circleLabel] ? self.tintColor.CGColor : self.lineColor.CGColor;
}

- (CGColorRef)lineInnerCircleColor:(CAShapeLayer *)lineCircle
{
    return self.sliderPosition + diff >= [self lineCirclePosition:lineCircle] ? self.innerCircleColor.CGColor : self.innerCircleNormalColor.CGColor;
}

#pragma mark - Touches

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    startTouchPosition = [touch locationInView:self];
    startSliderPosition = _sliderCircleLayer.position;
    
    if (CGRectContainsPoint(_sliderCircleLayer.frame, startTouchPosition)) {
        return YES;
    } else {
        for (NSUInteger i = 0; i < _lineCirclesArray.count; i++) {
            CALayer *dot = _lineCirclesArray[i];
            
            CGFloat dotRadiusDiff = 22 - self.lineCircleRadius;
            CGRect frameToCheck = dotRadiusDiff > 0 ? CGRectInset(dot.frame, -dotRadiusDiff, -dotRadiusDiff) : dot.frame;
            
            if (CGRectContainsPoint(frameToCheck, startTouchPosition)) {
                NSUInteger oldIndex = _index;
                
                _index = i;
                
                if (oldIndex != _index) {
                    [self sendActionsForControlEvents:UIControlEventValueChanged];
                }
                animateLayouts = YES;
                [self setNeedsLayout];
                return NO;
            }
        }
    }
    return NO;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGFloat position = startSliderPosition.x - (startTouchPosition.x - [touch locationInView:self].x);
    CGFloat limitedPosition = fminf(fmaxf(maxRadius, position), self.bounds.size.width - maxRadius);
    
    withoutCAAnimation(^{
        _sliderCircleLayer.position = CGPointMake(limitedPosition, _sliderCircleLayer.position.y);
        _lineLayer.path = [self fillingPath];
        
        NSUInteger index = (self.sliderPosition + diff) / (_lineLayer.bounds.size.width / (self.maxCount - 1));
        if (_index != index) {
            for (CAShapeLayer *lineCircle in _lineCirclesArray) {
                lineCircle.strokeColor = [self lineCircleColor:lineCircle];
                lineCircle.lineWidth = 2.0f;
                lineCircle.fillColor = [self lineInnerCircleColor:lineCircle];
            }
            
            for (PSTextLayer *circleLabel in _circleLabelsArray) {
                circleLabel.foregroundColor = [self circleLabelColor:circleLabel];
            }
            
            
            _index = index;
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
        
        
    });
    
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self endTouches];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
    [self endTouches];
}

- (void)endTouches
{
    NSUInteger newIndex = roundf([self indexCalculate]);
    
    if (newIndex != _index) {
        _index = newIndex;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    
    animateLayouts = YES;
    [self setNeedsLayout];
}

#pragma mark - Access methods

- (void)setIndex:(NSUInteger)index animated:(BOOL)animated
{
    animateLayouts = animated;
    self.index = index;
}

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    [self setNeedsLayout];
}

GEN_SETTER(index, NSUInteger, setIndex, [self sendActionsForControlEvents:UIControlEventValueChanged];);
GEN_SETTER(maxCount, NSUInteger, setMaxCount, [self updateIndex];);
GEN_SETTER(lineHeight, CGFloat, setLineHeight, [self updateDiff];);
GEN_SETTER(lineCircleRadius, CGFloat, setLineCircleRadius, [self updateDiff]; [self updateMaxRadius];);
GEN_SETTER(sliderCircleRadius, CGFloat, setSliderCircleRadius, [self updateMaxRadius];);
GEN_SETTER(lineColor, UIColor*, setLineColor, );
GEN_SETTER(sliderCircleColor, UIColor*, setSliderCircleColor, );

@end
