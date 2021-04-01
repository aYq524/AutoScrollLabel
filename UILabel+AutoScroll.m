//
//  UILabel+AutoScroll.m
//  labelExpand
//
//  Created by 李灿 on 2021/3/25.
//

#import "UILabel+AutoScroll.h"
#import <objc/runtime.h>

static NSString * textLayer = @"textLayer";
static NSString * scrollAnimation = @"scrollAnimation";

@implementation UILabel (AutoScroll)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method setTextMethod = class_getInstanceMethod(self, @selector(setText:));
        Method setColorMethod = class_getInstanceMethod(self, @selector(setTextColor:));
        Method setFontMethod = class_getInstanceMethod(self, @selector(setFont:));
        Method setFrameMethod = class_getInstanceMethod(self, @selector(setFrame:));
        Method drawTextMethon = class_getInstanceMethod(self, @selector(drawTextInRect:));
        
        Method scrollSetTextMethod = class_getInstanceMethod(self, @selector(autoScrollSetText:));
        Method scrollSetColorMethod = class_getInstanceMethod(self, @selector(autoScrollSetTextColor:));
        Method scrollSetFontMethod = class_getInstanceMethod(self, @selector(autoScrollSetFont:));
        Method scrollSetFrameMethod = class_getInstanceMethod(self, @selector(autoScrollSetFrame:));
        Method scrollDrawText = class_getInstanceMethod(self, @selector(autoScrollDrawText:));

        method_exchangeImplementations(setTextMethod, scrollSetTextMethod);
        method_exchangeImplementations(setColorMethod, scrollSetColorMethod);
        method_exchangeImplementations(setFontMethod, scrollSetFontMethod);
        method_exchangeImplementations(setFrameMethod, scrollSetFrameMethod);
        method_exchangeImplementations(drawTextMethon, scrollDrawText);
    });
    
}

/// 用于替换系统setText方法
/// @param text 标签显示的文字
- (void)autoScrollSetText:(NSString *)text
{
    [self autoScrollSetText:text];
    // 这句是为了让textlayer超出label的部分不显示
    self.layer.masksToBounds = true;
    [self setTextLayerScroll];
}

/// 用于替换系统setTextColor方法
/// @param color 文字颜色
- (void)autoScrollSetTextColor:(UIColor *)color
{
    [self autoScrollSetTextColor:color];
    [self setTextLayerScroll];
}

/// 用于替换系统的setFont方法
/// @param font 字体
- (void)autoScrollSetFont:(UIFont *)font
{
    [self autoScrollSetFont:font];
    [self setTextLayerScroll];
}

/// 用于替换系统的setFrame方法
/// @param frame 坐标
- (void)autoScrollSetFrame:(CGRect)frame
{
    [self autoScrollSetFrame:frame];
    [self setTextLayerScroll];
}

/// 用于替换系统的drawText方法
/// @param rect frame
- (void)autoScrollDrawText:(CGRect)rect
{
    BOOL shouldScroll = [self shouldAutoScroll];
    if (!shouldScroll)
    {
        [self autoScrollDrawText:rect];
    }
}

/// 根据文字长短自动判断是否需要显示TextLayer，并且滚动
- (void)setTextLayerScroll
{
    BOOL shouldScroll = [self shouldAutoScroll];
    CATextLayer * textLayer = [self getTextLayer];
    
    if (shouldScroll)
    {
        CABasicAnimation * ani = [self getAnimation];
        [textLayer addAnimation:ani forKey:nil];
        [self.layer addSublayer:textLayer];
    }
    else
    {
        [textLayer removeAllAnimations];
        [textLayer removeFromSuperlayer];
    }
}

/// runtime存放textLayer，避免多次生成
- (CATextLayer *)getTextLayer
{
    CATextLayer * layer = objc_getAssociatedObject(self, &textLayer);
    if (!layer) {
        layer = [CATextLayer layer];
        objc_setAssociatedObject(self, &textLayer, layer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    CGSize size = [self.text sizeWithAttributes:@{NSFontAttributeName:self.font}];
    CGFloat stringWidth = size.width;
    layer.frame = CGRectMake(0, 0, stringWidth, self.frame.size.height);
    layer.alignmentMode = kCAAlignmentCenter;
    layer.font = (__bridge CFTypeRef _Nullable)(self.font.fontName);
    layer.fontSize = self.font.pointSize;
    layer.foregroundColor = self.textColor.CGColor;
    layer.string = self.text;
    // 不写这句可能导致layer的文字在某些情况下不清晰
    layer.contentsScale = [UIScreen mainScreen].scale;
    return layer;
}

/// runtime存放动画对象，避免多次生成
- (CABasicAnimation *)getAnimation
{
    CABasicAnimation * ani = objc_getAssociatedObject(self, &scrollAnimation);
    if (!ani) {
        ani = [CABasicAnimation animationWithKeyPath:@"position.x"];
        objc_setAssociatedObject(self, &scrollAnimation, ani, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    CATextLayer * textLayer = [self getTextLayer];
    CGPoint point = textLayer.position;
    CGFloat lenth = textLayer.frame.size.width - self.frame.size.width;
    // 起点位置
    CGPoint pointSrc = CGPointMake(point.x + 20, point.y);
    // 终点位置
    CGPoint pointDes = CGPointMake(pointSrc.x - lenth - 30, pointSrc.y);
    id toValue = [NSValue valueWithCGPoint:pointDes];
    id fromValue = [NSValue valueWithCGPoint:pointSrc];
    ani.toValue = toValue;
    ani.fromValue = fromValue;
    ani.duration = 2;
    ani.fillMode = kCAFillModeBoth;
    ani.repeatCount = HUGE_VALF;
    // 结束后逆向执行动画
    ani.autoreverses = YES;
    ani.removedOnCompletion = false;
    return ani;
}

/// 判断是否需要滚动
- (BOOL)shouldAutoScroll
{
    BOOL shouldScroll = false;
    if (self.numberOfLines == 1) {
        CGSize size = [self.text sizeWithAttributes:@{NSFontAttributeName:self.font}];
        CGFloat stringWidth = size.width;
        CGFloat labelWidth = self.frame.size.width;
        if (labelWidth < stringWidth) {
            shouldScroll = true;
        }
    }
    return shouldScroll;
}

@end
