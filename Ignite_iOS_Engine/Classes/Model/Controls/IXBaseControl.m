//
//  IXBaseControl.m
//  Ignite iOS Engine (IX)
//
//  Created by Robert Walsh on 10/3/13.
//  Copyright (c) 2013 Apigee, Inc. All rights reserved.
//

#import "IXBaseControl.h"

#import "IXAppManager.h"
#import "IXPropertyContainer.h"
#import "ColorUtils.h"
#import "IXControlLayoutInfo.h"
#import "IXLogger.h"

#import "UIImage+ResizeMagick.h"
#import "Ignite_iOS_Engine-Swift.h"

#warning Clean this up and organize it into Attributes/Returns/Events/Functions

// Attributes
IX_STATIC_CONST_STRING kIXAlpha = @"alpha";
IX_STATIC_CONST_STRING kIXBorderWidth = @"border.size";
IX_STATIC_CONST_STRING kIXBorderColor = @"border.color";
IX_STATIC_CONST_STRING kIXBorderRadius = @"border.radius";
IX_STATIC_CONST_STRING kIXBackgroundColor = @"bg.color";
IX_STATIC_CONST_STRING kIXBackgroundImage = @"bg.image";
IX_STATIC_CONST_STRING kIXBackgroundImageScale = @"bg.scale";
IX_STATIC_CONST_STRING kIXCIContextResolution = @"pixelRatio";
IX_STATIC_CONST_STRING kIXEnabled = @"enabled";
IX_STATIC_CONST_STRING kIXEnableTap = @"tap.enabled";
IX_STATIC_CONST_STRING kIXEnableSwipe = @"swipe.enabled";
IX_STATIC_CONST_STRING kIXEnablePinch = @"pinch.enabled";
IX_STATIC_CONST_STRING kIXEnablePan = @"pan.enabled";
IX_STATIC_CONST_STRING kIXEnableLongPress = @"longPress.enabled";
IX_STATIC_CONST_STRING kIXEnableShadow = @"shadow.enabled";
IX_STATIC_CONST_STRING kIXShadowBlur = @"shadow.blur";
IX_STATIC_CONST_STRING kIXShadowAlpha = @"shadow.alpha";
IX_STATIC_CONST_STRING kIXShadowColor = @"shadow.color";
IX_STATIC_CONST_STRING kIXShadowOffsetRight = @"shadow.offset.r";
IX_STATIC_CONST_STRING kIXShadowOffsetDown = @"shadow.offset.b";
#warning Suspect the following "visible" is not required
// IX_STATIC_CONST_STRING kIXVisible = @"visible"; // pretty sure this is used in IXControlLayoutInfo only
IX_STATIC_CONST_STRING kIXPanReset = @"pan.resetOnRelease.enabled";
IX_STATIC_CONST_STRING kIXPanSnap = @"pan.snapToBounds.enabled";
IX_STATIC_CONST_STRING kIXTapCount = @"tap.count";
IX_STATIC_CONST_STRING kIXPinchZoom = @"pinch.direction"; //both (default), horizontal, or vertical
IX_STATIC_CONST_STRING kIXPinchReset = @"pinch.resetOnRelease.enabled";
IX_STATIC_CONST_STRING kIXPinchMax = @"pinch.zoomScale.max";
IX_STATIC_CONST_STRING kIXPinchMin = @"pinch.zoomScale.min";
IX_STATIC_CONST_STRING kIXPinchElastic = @"pinch.zoomScale.elasticity";

// Attribute Accepted Values
IX_STATIC_CONST_STRING kIXBackgroundImageScaleCover = @"cover"; // bg.scale
IX_STATIC_CONST_STRING kIXBackgroundImageScaleStretch = @"stretch"; // bg.scale
IX_STATIC_CONST_STRING kIXBackgroundImageScaleTile = @"tile"; // bg.scale
IX_STATIC_CONST_STRING kIXBackgroundImageScaleContain = @"contain"; // bg.scale
IX_STATIC_CONST_STRING kIXDown = @"down"; // swipe.direction
IX_STATIC_CONST_STRING kIXUp = @"up"; // swipe.direction
IX_STATIC_CONST_STRING kIXRight = @"right"; // swipe.direction
IX_STATIC_CONST_STRING kIXLeft = @"left"; // swipe.direction
IX_STATIC_CONST_STRING kIXPinchBoth = @"both"; // pinch.direction
IX_STATIC_CONST_STRING kIXPinchHorizontal = @"horizontal"; // pinch.direction
IX_STATIC_CONST_STRING kIXPinchVertical = @"vertical"; // pinch.direction
IX_STATIC_CONST_STRING kIXReverse = @"reverse"; // spin direction

// Attribute Defaults

// Returns
IX_STATIC_CONST_STRING kIXPinchTransformScale = @"transform.scale"; // pinch transform scale
IX_STATIC_CONST_STRING kIXLocation = @"position"; // what is returned here? comma separated?
IX_STATIC_CONST_STRING kIXLocationX = @"position.x";
IX_STATIC_CONST_STRING kIXLocationY = @"position.y";
IX_STATIC_CONST_STRING kIXActualHeight = @"size.h.computed";
IX_STATIC_CONST_STRING kIXActualWidth = @"size.w.computed";

// Events
IX_STATIC_CONST_STRING kIXTouch = @"touch";
IX_STATIC_CONST_STRING kIXTouchUp = @"touchUp";
IX_STATIC_CONST_STRING kIXTouchCancelled = @"touchCancelled";
IX_STATIC_CONST_STRING kIXTap = @"tap";
#warning Should support events on swipe.<direction> rather than this or make swipe.direction a read-only property
IX_STATIC_CONST_STRING kIXSwipe = @"swipe";
IX_STATIC_CONST_STRING kIXSwipeDirection = @"swipe.direction";
IX_STATIC_CONST_STRING kIXPan = @"pan";
IX_STATIC_CONST_STRING kIXLongPress = @"longPress";
IX_STATIC_CONST_STRING kIXPinchIn = @"pinch.in";
IX_STATIC_CONST_STRING kIXPinchOut = @"pinch.out";
IX_STATIC_CONST_STRING kIXSnapshotSaved = @"snapshot.success";
IX_STATIC_CONST_STRING kIXSnapshotFailed = @"snapshot.error";

// Functions
IX_STATIC_CONST_STRING kIXSpin = @"spin";
#warning Suspect the following "start_animation" is not required
IX_STATIC_CONST_STRING kIXStartAnimation = @"start_animation"; // deprecate?
IX_STATIC_CONST_STRING kIXStopAnimation = @"stopAnimating";
IX_STATIC_CONST_STRING kIXSnapshot = @"takeSnapshot";

// Function Params
IX_STATIC_CONST_STRING kIXDirection = @"direction"; // key value for "spin" animation param
IX_STATIC_CONST_STRING kIXSaveToLocation = @"saveToLocation";


// Animation Functions

// kIXSnapshot Parameters

// Functions & Helpers
IX_STATIC_CONST_STRING kIXToggle = @"dev_toggle";

@interface IXBaseControl ()

@property (nonatomic,assign,getter = isAnimating) BOOL animating;
@property (nonatomic,assign) NSInteger animationCounter;

@end

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@implementation IXBaseControl

static BOOL kIXDidDetermineOriginalCenter = false; // used for pan gesture

-(void)dealloc
{
    [self endAnimation];
}

-(id)init
{
    self = [super init];
    if( self )
    {
        _contentView = nil;
        _layoutInfo = nil;
        _notifyParentOfLayoutUpdates = YES;
        _animating = NO;
        _animationCounter = 0;
        
        [self buildView];
    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    IXBaseControl* baseControl = [super copyWithZone:zone];
    if( baseControl )
    {
        if( [self subControlsDictionary] )
        {
            [baseControl setSubControlsDictionary:[[NSDictionary alloc] initWithDictionary:[self subControlsDictionary] copyItems:YES]];
        }
    }
    return baseControl;
}

-(void)setPropertyContainer:(IXPropertyContainer *)propertyContainer
{
    [super setPropertyContainer:propertyContainer];
    [[self layoutInfo] setPropertyContainer:propertyContainer];
}

//
// If you override and need to add subviews to the control you need to call super first then add the subviews to the controls contentView.
// If you don't need a view for the control simply override this and do not call super.
//
-(void)buildView
{
    _layoutInfo = [[IXControlLayoutInfo alloc] init];
    _contentView = [[IXControlContentView alloc] initWithFrame:CGRectZero viewTouchDelegate:self];
    [_contentView setClipsToBounds:NO];
}

-(BOOL)isContentViewVisible
{
    BOOL isVisible = NO;
    if( [self contentView] )
    {
        if( ![[self contentView] isHidden] && [[self contentView] alpha] > 0.0f )
        {
            isVisible = YES;
        }
    }
    return isVisible;
}

-(CGSize)preferredSizeForSuggestedSize:(CGSize)size
{
    return CGSizeZero;
}

-(void)layoutControlContentsInRect:(CGRect)rect
{
    
}

-(void)layoutControl
{
    if( [self parentObject] && [self shouldNotifyParentOfLayoutUpdates] )
    {
        [((IXBaseControl*)[self parentObject]) layoutControl];
    }
    else
    {
        CGRect internalLayoutRect = [LayoutEngine calculateInternalLayoutRect:self rect:[[self contentView] bounds]];
        [self layoutControlContentsInRect:internalLayoutRect];
    }
}

-(void)applySettings
{
    [super applySettings];
    
    if( [self contentView] != nil )
    {
        if( _layoutInfo == nil )
        {
            _layoutInfo = [[IXControlLayoutInfo alloc] initWithPropertyContainer:[self propertyContainer]];
        }
        else
        {
            [_layoutInfo setPropertyContainer:[self propertyContainer]];
            [_layoutInfo refreshLayoutInfo];
        }
        
        [self applyContentViewSettings];
        [self applyGestureRecognizerSettings];
    }
    else
    {
        _layoutInfo = nil;
    }
    
    for( IXBaseControl* baseControl in [self childObjects] )
    {
        [baseControl applySettings];
    }
}

-(void)applyContentViewSettings
{
    NSString* backgroundImage = [[self propertyContainer] getStringPropertyValue:kIXBackgroundImage defaultValue:nil];
    if( backgroundImage )
    {

        NSString* backgroundImageScale = [[self propertyContainer] getStringPropertyValue:kIXBackgroundImageScale
                                                                             defaultValue:kIXBackgroundImageScaleCover];
        
        static NSDictionary *sIXBackgroundImageScaleFormatDictionary = nil;
# warning Not sure a dispatch_once is going to work properly here? Means you can never change it
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sIXBackgroundImageScaleFormatDictionary = @{kIXBackgroundImageScaleCover: @"%.0fx%.0f^",
                                                        kIXBackgroundImageScaleStretch: @"%.0fx%.0f!",
                                                        kIXBackgroundImageScaleTile: @"%.0fx%.0f",
                                                        kIXBackgroundImageScaleContain: @"%.0fx%.0f"};
        });
        
        NSString* backgroundImageScaleFormat = sIXBackgroundImageScaleFormatDictionary[backgroundImageScale];
        BOOL isScaleTypeContain = [backgroundImageScale isEqualToString:kIXBackgroundImageScaleContain];
        
        if( backgroundImageScaleFormat != nil )
        {
            __weak typeof(self) weakSelf = self;
            [[self propertyContainer] getImageProperty:kIXBackgroundImage successBlock:^(UIImage *image) {
                
                CGSize size = [[weakSelf contentView] bounds].size;
                
                image = [image resizedImageByMagick:[NSString stringWithFormat:backgroundImageScaleFormat,size.width,size.height]];
                
                if( isScaleTypeContain )
                {
                    UIGraphicsBeginImageContext(size);
                    
                    [[UIColor clearColor] setFill];
                    [[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, size.width, size.height)] fill];
                    
                    CGRect rect = CGRectMake(((size.width - image.size.width) / 2), ((size.height - image.size.height) / 2), image.size.width, image.size.height);
                    [image drawInRect:rect blendMode:kCGBlendModeNormal alpha:1.0];
                    image = UIGraphicsGetImageFromCurrentImageContext();
                    
                    UIGraphicsEndImageContext();
                }
                
                [[weakSelf contentView] setBackgroundColor:[UIColor colorWithPatternImage:image]];
                
            } failBlock:^(NSError *error) {

                [[weakSelf contentView] setBackgroundColor:[[weakSelf propertyContainer] getColorPropertyValue:kIXBackgroundColor defaultValue:[UIColor clearColor]]];
                
                IX_LOG_DEBUG(@"Background image failed to load at %@", kIXBackgroundImage);
            }];
        }
        else
        {
            [[self contentView] setBackgroundColor:[[self propertyContainer] getColorPropertyValue:kIXBackgroundColor defaultValue:[UIColor clearColor]]];
        }
    }
    else
    {
        [[self contentView] setBackgroundColor:[[self propertyContainer] getColorPropertyValue:kIXBackgroundColor defaultValue:[UIColor clearColor]]];
    }
    
    [[self contentView] setEnabled:[[self propertyContainer] getBoolPropertyValue:kIXEnabled defaultValue:YES]];
    [[self contentView] setHidden:[[self layoutInfo] isHidden]];
    [[self contentView] setAlpha:[[self propertyContainer] getFloatPropertyValue:kIXAlpha defaultValue:1.0f]];
    
    float borderWidth = [[self propertyContainer] getFloatPropertyValue:kIXBorderWidth defaultValue:0.0f];
    UIColor* borderColor = [[self propertyContainer] getColorPropertyValue:kIXBorderColor defaultValue:[UIColor blackColor]];
    if( [[IXAppManager sharedAppManager] isLayoutDebuggingEnabled] )
    {
        if( borderWidth == 0.0f )
        {
            borderWidth = 1.0f;
            CGFloat hue = ( arc4random() % 256 / 256.0f );
            CGFloat saturation = ( arc4random() % 128 / 256.0f ) + 0.5f;
            CGFloat brightness = ( arc4random() % 128 / 256.0f ) + 0.5f;
            borderColor = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1.0f];
        }
    }
    [[[self contentView] layer] setBorderWidth:borderWidth];
    [[[self contentView] layer] setBorderColor:borderColor.CGColor];
    [[[self contentView] layer] setCornerRadius:[[self propertyContainer] getFloatPropertyValue:kIXBorderRadius defaultValue:0.0f]];
    
    BOOL enableShadow = [[self propertyContainer] getBoolPropertyValue:kIXEnableShadow defaultValue:NO];
    if( enableShadow )
    {
        [[[self contentView] layer] setShouldRasterize:YES];
        [[[self contentView] layer] setRasterizationScale:[[UIScreen mainScreen] scale]];
        [[[self contentView] layer] setShadowRadius:[[self propertyContainer] getFloatPropertyValue:kIXShadowBlur defaultValue:1.0f]];
        [[[self contentView] layer] setShadowOpacity:[[self propertyContainer] getFloatPropertyValue:kIXShadowAlpha defaultValue:1.0f]];
        
        UIColor* shadowColor = [[self propertyContainer] getColorPropertyValue:kIXShadowColor defaultValue:[UIColor blackColor]];
        [[[self contentView] layer] setShadowColor:shadowColor.CGColor];
        
        float shadowOffsetRight = [[self propertyContainer] getFloatPropertyValue:kIXShadowOffsetRight defaultValue:2.0f];
        float shadowOffsetDown = [[self propertyContainer] getFloatPropertyValue:kIXShadowOffsetDown defaultValue:2.0f];
        [[[self contentView] layer] setShadowOffset:CGSizeMake(shadowOffsetRight, shadowOffsetDown)];
    }
    else
    {
        [[[self contentView] layer] setShouldRasterize:NO];
        [[[self contentView] layer] setShadowOpacity:0.0f];
    }
}

-(void)applyGestureRecognizerSettings
{
    if( [[self propertyContainer] getBoolPropertyValue:kIXEnableTap defaultValue:NO] ) {
        [[self contentView] beginListeningForTapGestures];
    } else {
        [[self contentView] stopListeningForTapGestures];
    }
    
    if( [[self propertyContainer] getBoolPropertyValue:kIXEnableSwipe defaultValue:NO] ) {
        [[self contentView] beginListeningForSwipeGestures];
    } else {
        [[self contentView] stopListeningForSwipeGestures];
    }
    
    if( [[self propertyContainer] getBoolPropertyValue:kIXEnablePinch defaultValue:NO] ){
        [[self contentView] beginListeningForPinchGestures];
    } else {
        [[self contentView] stopListeningForPinchGestures];
    }
    
    if( [[self propertyContainer] getBoolPropertyValue:kIXEnablePan defaultValue:NO] ) {
        [[self contentView] beginListeningForPanGestures];
    } else {
        [[self contentView] stopListeningForPanGestures];
    }

    if( [[self propertyContainer] getBoolPropertyValue:kIXEnableLongPress defaultValue:NO] ) {
        [[self contentView] beginListeningForLongPress];
    } else {
        [[self contentView] stopListeningForLongPress];
    }
}

-(void)controlViewTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch* touch = [[event allTouches] anyObject];
    IXBaseControl* touchedControl = [self getTouchedControl:touch];
    
    [touchedControl processBeginTouch:YES];
}

-(void)controlViewTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

-(void)controlViewTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self processCancelTouch:YES];
}

-(void)controlViewTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //    UITouch* touch = [touches anyObject];
    //    BOOL shouldFireTouchActions = ( [touch view] == [self contentView] && [touch tapCount] >= 1 );
    
    [self processEndTouch:YES];
}

-(void)controlViewTapGestureRecognized:(UITapGestureRecognizer *)tapGestureRecognizer
{
    NSString* tapCount = [NSString stringWithFormat:@"%lu",(unsigned long)[tapGestureRecognizer numberOfTapsRequired]];
    [[self actionContainer] executeActionsForEventNamed:kIXTap propertyWithName:kIXTapCount mustHaveValue:tapCount];
}

-(void)controlViewLongPressRecognized:(UILongPressGestureRecognizer*)panGestureRecognizer
{
    [[self actionContainer] executeActionsForEventNamed:kIXLongPress];
}

-(void)controlViewSwipeGestureRecognized:(UISwipeGestureRecognizer *)swipeGestureRecognizer
{
    NSString* swipeDirection = nil;
    switch ([swipeGestureRecognizer direction]) {
        case UISwipeGestureRecognizerDirectionDown:{
            swipeDirection = kIXDown;
            break;
        }
        case UISwipeGestureRecognizerDirectionLeft:{
            swipeDirection = kIXLeft;
            break;
        }
        case UISwipeGestureRecognizerDirectionRight:{
            swipeDirection = kIXRight;
            break;
        }
        case UISwipeGestureRecognizerDirectionUp:{
            swipeDirection = kIXUp;
            break;
        }
        default:{
            break;
        }
    }
    if( swipeDirection )
    {
        [[self actionContainer] executeActionsForEventNamed:kIXSwipe propertyWithName:kIXSwipeDirection mustHaveValue:swipeDirection];
    }
}

-(void)controlViewPinchGestureRecognized:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    NSString* zoomDirection = [[self propertyContainer] getStringPropertyValue:kIXPinchZoom defaultValue:nil];
    
    if( zoomDirection != nil )
    {
        
        BOOL shouldResetPinchZoomOnTouchUp = [self.propertyContainer getBoolPropertyValue:kIXPinchReset defaultValue:YES];
        const CGFloat kMinScale = [self.propertyContainer getFloatPropertyValue:kIXPinchMin defaultValue:1.0];
        const CGFloat kMaxScale = [self.propertyContainer getFloatPropertyValue:kIXPinchMax defaultValue:2.0];
        const CGFloat kElastic = [self.propertyContainer getFloatPropertyValue:kIXPinchElastic defaultValue:0.5];
        
        CGFloat previousScale = 1;
        
        if(pinchGestureRecognizer.state == UIGestureRecognizerStateBegan) {
            // Reset the last scale, necessary if there are multiple objects with different scales
            previousScale = pinchGestureRecognizer.scale;
        }
        
        if(pinchGestureRecognizer.state == UIGestureRecognizerStateBegan ||
           pinchGestureRecognizer.state == UIGestureRecognizerStateChanged)
        {
            CGAffineTransform transform = CGAffineTransformIdentity;
            CGFloat currentScale = [[pinchGestureRecognizer.view.layer valueForKeyPath:kIXPinchTransformScale] floatValue];
            CGFloat newScale = 1 - (previousScale - pinchGestureRecognizer.scale);
            newScale = MIN(newScale, (kMaxScale + kElastic) / currentScale);
            newScale = MAX(newScale, (kMinScale - kElastic) / currentScale);
            if ([zoomDirection isEqualToString:kIXPinchVertical])
            {
                transform = CGAffineTransformScale(pinchGestureRecognizer.view.transform, 1, newScale);
            }
            else if ([zoomDirection isEqualToString:kIXPinchHorizontal])
            {
                transform = CGAffineTransformScale(pinchGestureRecognizer.view.transform, newScale, 1);
            }
            else if ([zoomDirection isEqualToString:kIXPinchBoth])
            {
                transform = CGAffineTransformScale(pinchGestureRecognizer.view.transform, newScale, newScale);
            }
            pinchGestureRecognizer.view.transform = transform;
            previousScale = pinchGestureRecognizer.scale;
            pinchGestureRecognizer.scale = 1;
        }
        
        if(pinchGestureRecognizer.state == UIGestureRecognizerStateEnded ||
           pinchGestureRecognizer.state == UIGestureRecognizerStateCancelled)
        {
            if (shouldResetPinchZoomOnTouchUp)
            {
                CGAffineTransform resetTransform;
                CGFloat currentScale = [[pinchGestureRecognizer.view.layer valueForKeyPath:kIXPinchTransformScale] floatValue];
                CGFloat resetWidth = currentScale;
                CGFloat resetHeight = currentScale;
                if (currentScale < kMinScale)
                {
                    resetWidth = kMinScale;
                    resetHeight = kMinScale;
                    
                }
                else if (currentScale > kMaxScale)
                {
                    resetWidth = kMaxScale;
                    resetHeight = kMaxScale;
                }
                
                if ([zoomDirection isEqualToString:kIXPinchVertical])
                    resetHeight = 1;
                else if ([zoomDirection isEqualToString:kIXPinchHorizontal])
                    resetWidth = 1;
                
                resetTransform = CGAffineTransformMakeScale(resetHeight, resetWidth);
                
                if (currentScale > kMaxScale || currentScale < kMinScale)
                {
                    [UIView animateWithDuration:0.2
                                     animations:^{
                                         pinchGestureRecognizer.view.transform = resetTransform;
                                     }];
                     
                }
            }
            

        }
    }
    if(pinchGestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        //Pinch out
        if (pinchGestureRecognizer.scale > 1)
        {
            [[self actionContainer] executeActionsForEventNamed:kIXPinchOut];
        }
        //Pinch in
        else if (pinchGestureRecognizer.scale < 1)
        {
            [[self actionContainer] executeActionsForEventNamed:kIXPinchIn];
        }
    }
}

-(void)controlViewPanGestureRecognized:(UIPanGestureRecognizer *)panGestureRecognizer
{
    BOOL shouldResetPanPosition = [self.propertyContainer getBoolPropertyValue:kIXPanReset defaultValue:NO];
    BOOL panShouldSnapToBounds = [self.propertyContainer getBoolPropertyValue:kIXPanSnap defaultValue:YES];
    static CGPoint originalCenter;
    UIView *draggedView = panGestureRecognizer.view;
    CGPoint offset = [panGestureRecognizer translationInView:draggedView.superview];
    CGPoint center = draggedView.center;
    
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan && !kIXDidDetermineOriginalCenter)
    {
        originalCenter = draggedView.center;
        kIXDidDetermineOriginalCenter = true;
    }
    
    draggedView.center = CGPointMake(center.x + offset.x, center.y + offset.y);
    
    if ((panGestureRecognizer.state == UIGestureRecognizerStateEnded ||
         panGestureRecognizer.state == UIGestureRecognizerStateCancelled))
    {
        if (shouldResetPanPosition)
        {
            [UIView animateWithDuration:0.2
                             animations:^{
                                 draggedView.center = originalCenter;
                             }];
        }
        else if (panShouldSnapToBounds)
        {
            [UIView animateWithDuration:0.2
                             animations:^{
                                 draggedView.center = [self correctCenterIfOutsideView:draggedView fromOriginalCenter:originalCenter];
                                 //draggedView.center = originalCenter;
                             }];
        }
    }
    
    
    // Reset translation to zero so on the next `panWasRecognized:` message, the
    // translation will just be the additional movement of the touch since now.
    [panGestureRecognizer setTranslation:CGPointZero inView:draggedView.superview];
}

-(CGPoint)correctCenterIfOutsideView:(UIView *)view fromOriginalCenter:(CGPoint)originalCenter
{
    CGFloat newCenterX = view.center.x;
    CGFloat newCenterY = view.center.y;
    
    CGFloat currentLeft = view.frame.origin.x;
    CGFloat currentRight = view.frame.origin.x + view.frame.size.width;
    CGFloat currentTop = view.frame.origin.y;
    CGFloat currentBottom = view.frame.origin.y + view.frame.size.height;
    
    CGFloat originalLeft = originalCenter.x - (view.bounds.size.width / 2);
    CGFloat originalRight = originalCenter.x + (view.bounds.size.width / 2);
    CGFloat originalTop = originalCenter.y - (view.bounds.size.height / 2);
    CGFloat originalBottom = originalCenter.y + (view.bounds.size.height / 2);

    if (currentLeft > originalLeft && currentRight > originalRight)
        newCenterX = newCenterX - currentLeft + originalLeft;
    else if (currentRight < originalRight && currentLeft < originalLeft)
        newCenterX = newCenterX - currentRight + originalRight;
    
    if (currentTop > originalTop && currentBottom > originalBottom)
        newCenterY = newCenterY - currentTop + originalTop;
    else if (currentBottom < originalBottom && currentTop < originalTop)
        newCenterY = newCenterY - currentBottom + originalBottom;
    
    return CGPointMake(newCenterX, newCenterY);
}

-(IXBaseControl*)getTouchedControl:(UITouch*)touch
{
    if( touch == nil )
        return nil;
    
    IXBaseControl* returnControl = self;
    for( IXBaseControl* baseControl in [self childObjects] )
    {
        IXControlContentView* baseControlView = [baseControl contentView];
        if( baseControlView )
        {
            if( ![[baseControl contentView] isHidden]) // previously: && [baseControlView alpha] > 0.0f
            {
                if( CGRectContainsPoint([baseControlView bounds], [touch locationInView:baseControlView]) )
                {
                    returnControl = [baseControl getTouchedControl:touch];
                }
            }
        }
    }
    return returnControl;
}

-(NSString*)getReadOnlyPropertyValue:(NSString*)propertyName
{
    NSString* returnValue = nil;
    if ( [propertyName hasPrefix:kIXLocation] && [[self propertyContainer] hasLayoutProperties] )
    {
        UIView* rootView = [[[[[UIApplication sharedApplication] windows] firstObject] rootViewController] view];
        CGPoint location = [self.contentView convertPoint:self.contentView.frame.origin toView:rootView];
        
        if ( [propertyName isEqualToString:kIXLocationX] )
            returnValue = [NSString stringWithFormat:@"%f", location.x / 2];
        if ( [propertyName isEqualToString:kIXLocationY] )
            returnValue = [NSString stringWithFormat:@"%f", location.y / 2];
        if ( [propertyName isEqualToString:kIXLocation] )
            returnValue = NSStringFromCGPoint(CGPointMake(location.x / 2, location.y / 2));
    }
    if ( [propertyName hasPrefix:kIXActualHeight] && [[self propertyContainer] hasLayoutProperties] )
    {
        CGFloat selfHeight=self.contentView.bounds.size.height;
        returnValue = [NSString stringWithFormat: @"%.0f", selfHeight];
    }
    if ( [propertyName hasPrefix:kIXActualWidth] && [[self propertyContainer] hasLayoutProperties] )
    {
        CGFloat selfWidth=self.contentView.bounds.size.width;
        returnValue = [NSString stringWithFormat: @"%.0f", selfWidth];
    }
    return returnValue;
}

-(void)applyFunction:(NSString *)functionName withParameters:(IXPropertyContainer *)parameterContainer
{
    if( [functionName isEqualToString:kIXToggle] )
    {
        if ([self isContentViewVisible])
        {
            self.contentView.alpha = 0.0f;
            self.contentView.enabled = NO;
        }
        else
        {
            CGFloat originalAlpha = [[self propertyContainer] getFloatPropertyValue:kIXAlpha defaultValue:1.0f];
            if (originalAlpha <= 0)
                originalAlpha = 1;
            self.contentView.alpha = originalAlpha;
            self.contentView.enabled = YES;
        }
    }
    else if ([functionName isEqualToString:kIXSnapshot] )
    {
        if( [self contentView] )
        {
            CGFloat ciResolution = [[self propertyContainer] getFloatPropertyValue:kIXCIContextResolution defaultValue:0];
            UIGraphicsBeginImageContextWithOptions([self contentView].bounds.size, YES, ciResolution);
            [[self contentView] drawViewHierarchyInRect:[self contentView].bounds afterScreenUpdates:YES];
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

            NSString* saveToLocation = [parameterContainer getPathPropertyValue:kIXSaveToLocation basePath:nil defaultValue:nil];
            NSData* imageData = UIImagePNGRepresentation(image);
            if( [imageData length] > 0 && [saveToLocation length] > 0 )
            {
                NSError* __autoreleasing error;
                [imageData writeToFile:saveToLocation options:NSDataWritingAtomic error:&error];
                if( error == nil )
                {
                    [[self actionContainer] executeActionsForEventNamed:kIXSnapshotSaved];
                }
                else
                {
                    [[self actionContainer] executeActionsForEventNamed:kIXSnapshotFailed];
                }
            }
            else
            {
                [[self actionContainer] executeActionsForEventNamed:kIXSnapshotFailed];
            }
        }
        else
        {
            [[self actionContainer] executeActionsForEventNamed:kIXSnapshotFailed];
        }
    }
    else if ([functionName isEqualToString:kIXStopAnimation])
    {
        [self endAnimation];
    }
}

-(void)processBeginTouch:(BOOL)fireTouchActions
{
    if( fireTouchActions )
    {
        if( [[self actionContainer] hasActionsWithEventNamePrefix:kIXTouch] )
        {
            [[self actionContainer] executeActionsForEventNamed:kIXTouch];
        }
        else if( [[self parentObject] isKindOfClass:[IXBaseControl class]] )
        {
            IXBaseControl* parentControl = (IXBaseControl*)[self parentObject];
            if( [parentControl contentView] )
            {
                [parentControl processBeginTouch:fireTouchActions];
            }
        }
    }
}

-(void)processCancelTouch:(BOOL)fireTouchActions
{
    if( fireTouchActions )
    {
        IXBaseControl* parentControl = (IXBaseControl*)[self parentObject];
        if( [parentControl contentView] )
        {
            [parentControl processCancelTouch:fireTouchActions];
        }
        [[self actionContainer] executeActionsForEventNamed:kIXTouchCancelled];
    }
}

-(void)processEndTouch:(BOOL)fireTouchActions
{
    if( fireTouchActions )
    {
        IXBaseControl* parentControl = (IXBaseControl*)[self parentObject];
        if( [parentControl contentView] )
        {
            [parentControl processEndTouch:fireTouchActions];
        }
        [[self actionContainer] executeActionsForEventNamed:kIXTouchUp];
    }
}

-(void)beginAnimation:(NSString*)animation duration:(CGFloat)duration repeatCount:(NSInteger)repeatCount params:(NSDictionary*)params
{
    if ([animation isEqualToString:kIXSpin])
    {
        if (![self isAnimating]) {
            [self setAnimating:YES];
            [self setAnimationCounter:0];
            [self spinWithOptions: UIViewAnimationOptionCurveLinear duration:duration repeatCount:repeatCount*4 - 1 params:params]; //*4 to = 360º
        }
    }
}

-(void)endAnimation
{
    [self setAnimating:NO];
}

// ROTATE/SPIN ANIMATION

- (void)spinWithOptions: (UIViewAnimationOptions) options duration:(CGFloat)duration repeatCount:(NSInteger)repeatCount params:(NSDictionary*)params {

    // Required in order to prevent animation if the object is hidden
    if ([self isContentViewVisible])
    {

        // this spin completes 360 degrees every 1/4 of duration
        NSInteger degrees = 90;
        if ([[params objectForKey:kIXDirection] isEqualToString:kIXReverse])
        {
            degrees = -90;
        }
        
        [UIView animateWithDuration: duration / 4
                              delay: 0.0f
                            options: options
                         animations: ^{
                             self.contentView.transform = CGAffineTransformRotate(self.contentView.transform, DEGREES_TO_RADIANS(degrees));
                         }
                         completion: ^(BOOL finished) {
                             if (finished) {
                                 if ([self isAnimating] && ([self animationCounter] == 0 || [self animationCounter] < repeatCount))
                                 {
                                     if (repeatCount > 0)
                                     {
                                         [self setAnimationCounter:[self animationCounter]+1];
                                     }
                                     // if flag still set, keep spinning with constant speed
                                     [self spinWithOptions: UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveLinear duration:duration repeatCount:repeatCount params:params];
                                 } else if (options != UIViewAnimationOptionCurveEaseOut) {
                                     // one last spin, with deceleration
                                     [self spinWithOptions: UIViewAnimationOptionCurveEaseOut duration:duration repeatCount:repeatCount params:params];
                                 }
                             }
                         }];
    }
}

-(void)conserveMemory
{
    for( IXBaseControl* control in [self childObjects] )
    {
        [control conserveMemory];
    }
}

@end
