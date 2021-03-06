//
//  XYKeyboardHelper.m
//  JoinShow
//
//  Created by Heaven on 13-10-29.
//  Copyright (c) 2013年 Heaven. All rights reserved.
//
///////////////////////////////////////////////////////////////////////////////



/*
 
 /-----------------------------------------------------------------------------------------------------------\
 \-----------------------------------------------------------------------------------------------------------/
 |                                          iOS UINotification Mechanism                                    |
 /-----------------------------------------------------------------------------------------------------------\
 \-----------------------------------------------------------------------------------------------------------/
 
 1) Begin Editing:-         When TextField begin editing.
 2) End Editing:-           When TextField end editing.
 3) Switch TextField:-      When Keyboard Switch from a TextField to another TextField.
 3) Orientation Change:-    When Device Orientation Change.
 
 
 
 
 
 Begin Editing
 -------------------------------------------------           -------------------------------------------------   UITextFieldTextDidBeginEditingNotification  | --------> |          UIKeyboardWillShowNotification       |
 -------------------------------------------------           -------------------------------------------------
 ^------------------------Switch TextField--------^      ^
 |                                                       |
 |                                                       |
 | Switch TextField                                      | Orientation Change
 |                                                       |
 |                                                       |
 |                                                       |
 -------------------------------------------------           -------------------------------------------------
 |   UITextFieldTextDidEndEditingNotification    | <-------- |          UIKeyboardWillHideNotification       |
 -------------------------------------------------           -------------------------------------------------
 End Editing
 
 
 
 /-----------------------------------------------------------------------------------------------------------\
 \-----------------------------------------------------------------------------------------------------------/
 */

#import "XYKeyboardHelper.h"

@interface XYKeyboardHelper ()
{
    //Boolean to maintain keyboard is showing or it is hide. To solve rootViewController.view.frame calculations;
    BOOL isKeyboardShowing;
    
    //To save rootViewController.view.frame.
    CGRect topViewBeginRect;
    
    //TextField or TextView object.
    __weak UIView *textFieldView;
    
    //To save keyboard animation duration.
    CGFloat animationDuration;
    
    // To save keyboard size
    CGSize kbSize;
}

@end

@implementation XYKeyboardHelper __DEF_SINGLETON

-(id) init
{
    if (self = [super init])
    {
        _keyboardDistanceFromTextField = XYKeyboardHelper_DefaultDistance;
        _isEnabled = NO;
        animationDuration = 0.25;
    }
    return self;
}
- (void)setTextFieldDistanceFromKeyboard:(CGFloat)distance
{
    //Setting keyboard distance.
    self.keyboardDistanceFromTextField = MAX(distance, 0);
}
- (void)enableKeyboardHelper
{
    //registering for notifications if it is not enable already.
    if (self.isEnabled == NO)
    {
        self.isEnabled = YES;
        /*Registering for keyboard notification*/
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        
        /*Registering for textField notification*/
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidBeginEditing:) name:UITextFieldTextDidBeginEditingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidEndEditing:) name:UITextFieldTextDidEndEditingNotification object:nil];
        
        /*Registering for textView notification*/
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewdDidEndEditing:) name:UITextViewTextDidEndEditingNotification object:nil];
    }
    else
    {
    }
}

- (void)disableKeyboardHelper
{
    //Unregister for all notifications if it is enabled.
    if (self.isEnabled == YES)
    {
        self.isEnabled = NO;
        self.keyboardDistanceFromTextField = XYKeyboardHelper_DefaultDistance;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    else
    {
    }
}
#pragma mark - Helper Animation function
//Helper function to manipulate RootViewController's frame with animation.
- (void)setRootViewFrame:(CGRect)frame
{
    
//    if (isKeyboardShowing == YES && ABS(frame.origin.x) <= 0.01 && ABS(frame.origin.y) <= 0.01) {
//        return;
//    }
  //  NSLogD(@"%@", NSStringFromCGRect(frame));
    //Getting topMost ViewController.
    UIViewController *controller = [XYCommon topMostController];
    
    [UIView animateWithDuration:animationDuration animations:^{
        
        //Setting it's new frame
        [controller.view setFrame:frame];
    }];
}

#pragma mark - UIKeyboad Delegate methods
// Keyboard Will hide. So setting rootViewController to it's default frame.
- (void)keyboardWillHide:(NSNotification*)aNotification
{
    //Boolean to know keyboard is showing/hiding
    isKeyboardShowing = NO;
    
    //Getting keyboard animation duration
    CGFloat aDuration = [[aNotification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    if (aDuration!= 0.0f)
    {
        //Setitng keyboard animation duration
        animationDuration = [[aNotification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    }
    
    //Setting rootViewController frame to it's original position.
    [self setRootViewFrame:topViewBeginRect];
}

//UIKeyboard Did show
- (void)keyboardDidShow:(NSNotification*)aNotification
{
    // 临时解决 也许有bug
    // UIKeyboardDidShowNotification ---> UITextViewTextDidBeginEditingNotification
    // UITextFieldTextDidBeginEditingNotification ---> UIKeyboardDidShowNotification
    // UITextView 和 UITextField 的键盘出现的消息的顺序不一样的问题
    /*
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    UIView *firstResponder = [keyWindow performSelector:@selector(firstResponder)];
    textFieldView = firstResponder;
     */
    
    [self commonDidBeginEditing];
  //  NSLogD(@"%@", firstResponder);
    
    //Getting keyboard animation duration
    CGFloat duration = [[aNotification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    //Getting UIKeyboardSize.
    kbSize = [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    //Adding Keyboard distance from textField.
    switch ([XYCommon topMostController].interfaceOrientation)
    {
        case UIInterfaceOrientationLandscapeLeft:
            kbSize.width += _keyboardDistanceFromTextField;
            break;
        case UIInterfaceOrientationLandscapeRight:
            kbSize.width += _keyboardDistanceFromTextField;
            break;
        case UIInterfaceOrientationPortrait:
            kbSize.height += _keyboardDistanceFromTextField;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            kbSize.height += _keyboardDistanceFromTextField;
            break;
        default:
            break;
    }
    
    [self adjustFrameWithDuration:duration];
}

//UIKeyboard Did show. Adjusting RootViewController's frame according to device orientation.
- (void)adjustFrameWithDuration:(CGFloat)aDuration {
    //Boolean to know keyboard is showing/hiding
    isKeyboardShowing = YES;
    
    if (aDuration!= 0.0f)
    {
        //Setitng keyboard animation duration
        animationDuration = aDuration;
    }
    
    //Getting KeyWindow object.
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    //Getting RootViewController's view.
    UIViewController *rootController = [XYCommon topMostController];
    
    //Converting Rectangle according to window bounds.
    CGRect textFieldViewRect = [textFieldView.superview convertRect:textFieldView.frame toView:window];
    //Getting RootViewRect.
    CGRect rootViewRect = rootController.view.frame;
    
    CGFloat move;
    //Move positive = textField is hidden.
    //Move negative = textField is showing.
    
    //Calculating move position. Common for both normal and special cases.
    switch (rootController.interfaceOrientation)
    {
        case UIInterfaceOrientationLandscapeLeft:
            move = CGRectGetMaxX(textFieldViewRect)-(CGRectGetWidth(window.frame)-kbSize.width);
            break;
        case UIInterfaceOrientationLandscapeRight:
            move = kbSize.width-CGRectGetMinX(textFieldViewRect);
            break;
        case UIInterfaceOrientationPortrait:
            move = CGRectGetMaxY(textFieldViewRect)-(CGRectGetHeight(window.frame)-kbSize.height);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            move = kbSize.height-CGRectGetMinY(textFieldViewRect);
            break;
        default:
            break;
    }
    
    //Special case.
    if ([[XYCommon topMostController] modalPresentationStyle] == UIModalPresentationFormSheet ||
        [[XYCommon topMostController] modalPresentationStyle] == UIModalPresentationPageSheet)
    {
        //Positive or zero.
        if (move>=0)
        {
            //We should only manipulate y.
            rootViewRect.origin.y -= move;
            [self setRootViewFrame:rootViewRect];
        }
        //Negative
        else
        {
            //Calculating disturbed distance
            CGFloat disturbDistance = CGRectGetMinY(rootViewRect)-CGRectGetMinY(topViewBeginRect);
            
            //Move Negative = frame disturbed.
            //Move positive or frame not disturbed.
            if(disturbDistance<0)
            {
                //We should only manipulate y.
                rootViewRect.origin.y -= MAX(move, disturbDistance);
                [self setRootViewFrame:rootViewRect];
            }
        }
    }
    else
    {
        //Positive or zero.
        if (move>=0)
        {
            //adjusting rootViewRect
            switch (rootController.interfaceOrientation)
            {
                case UIInterfaceOrientationLandscapeLeft:       rootViewRect.origin.x -= move;  break;
                case UIInterfaceOrientationLandscapeRight:      rootViewRect.origin.x += move;  break;
                case UIInterfaceOrientationPortrait:            rootViewRect.origin.y -= move;  break;
                case UIInterfaceOrientationPortraitUpsideDown:  rootViewRect.origin.y += move;  break;
                default:    break;
            }
            
            //Setting adjusted rootViewRect
            [self setRootViewFrame:rootViewRect];
        }
        //Negative
        else
        {
            CGFloat disturbDistance = 0;
            
            //Calculating disturbed distance
            switch (rootController.interfaceOrientation)
            {
                case UIInterfaceOrientationLandscapeLeft:
                    disturbDistance = CGRectGetMinX(rootViewRect)-CGRectGetMinX(topViewBeginRect);
                    break;
                case UIInterfaceOrientationLandscapeRight:
                    disturbDistance = CGRectGetMinX(topViewBeginRect)-CGRectGetMinX(rootViewRect);
                    break;
                case UIInterfaceOrientationPortrait:
                    disturbDistance = CGRectGetMinY(rootViewRect)-CGRectGetMinY(topViewBeginRect);
                    break;
                case UIInterfaceOrientationPortraitUpsideDown:
                    disturbDistance = CGRectGetMinY(topViewBeginRect)-CGRectGetMinY(rootViewRect);
                    break;
                default:
                    break;
            }
            
            //Move Negative = frame disturbed.
            //Move positive or frame not disturbed.
            if(disturbDistance<0)
            {
                //adjusting rootViewRect
                switch (rootController.interfaceOrientation)
                {
                    case UIInterfaceOrientationLandscapeLeft:       rootViewRect.origin.x -= MAX(move, disturbDistance);  break;
                    case UIInterfaceOrientationLandscapeRight:      rootViewRect.origin.x += MAX(move, disturbDistance);  break;
                    case UIInterfaceOrientationPortrait:            rootViewRect.origin.y -= MAX(move, disturbDistance);  break;
                    case UIInterfaceOrientationPortraitUpsideDown:  rootViewRect.origin.y += MAX(move, disturbDistance);  break;
                    default:    break;
                }
                
                //Setting adjusted rootViewRect
                [self setRootViewFrame:rootViewRect];
            }
        }
    }    
}

#pragma mark - UITextField Delegate methods
//Fetching UITextField object from notification.
- (void)textFieldDidBeginEditing:(NSNotification*)notification
{
   // NSLogDD
    textFieldView = notification.object;
    [self commonDidBeginEditing];
}

//Removing fetched object.
- (void)textFieldDidEndEditing:(NSNotification*)notification
{
    textFieldView = nil;
}

#pragma mark - UITextView Delegate methods
//Fetching UITextView object from notification.
- (void)textViewDidBeginEditing:(NSNotification*)notification
{
  //  NSLogDD
    textFieldView = notification.object;
    [self commonDidBeginEditing];
}

//Removing fetched object.
- (void)textViewdDidEndEditing:(NSNotification*)notification
{
    textFieldView = nil;
}

// Common code to perform on begin editing
- (void)commonDidBeginEditing {
    if (isKeyboardShowing)
    {
        // keyboard is already showing. adjust frame.
        [self adjustFrameWithDuration:0];
    }
    else
    {
        //keyboard is not showing(At the beginning only). We should save rootViewRect.
        UIViewController *rootController = [XYCommon topMostController];
        topViewBeginRect = rootController.view.frame;
    }
}

@end

/*Additional Function*/
@implementation UITextField(ToolbarOnKeyboard)

#pragma mark - Toolbar on UIKeyboard
- (void)addDoneOnKeyboardWithTarget:(id)target action:(SEL)action
{
    //Creating a toolBar for phoneNumber keyboard
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [toolbar setBarStyle:UIBarStyleBlackTranslucent];
    [toolbar sizeToFit];
    
    //Create a button to show on phoneNumber keyboard to resign it. Adding a selector to resign it.
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:target action:action];
    
    //Create a fake button to maintain flexibleSpace between doneButton and nilButton. (Actually it moves done button to right side.
    UIBarButtonItem *nilButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    //Adding button to toolBar.
    [toolbar setItems:[NSArray arrayWithObjects: nilButton,doneButton, nil]];
    
    //Setting toolbar to textFieldPhoneNumber keyboard.
    [self setInputAccessoryView:toolbar];
}

- (void)addPreviousNextDoneOnKeyboardWithTarget:(id)target previousAction:(SEL)previousAction nextAction:(SEL)nextAction doneAction:(SEL)doneAction
{
    //Creating a toolBar for phoneNumber keyboard
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [toolbar setBarStyle:UIBarStyleBlackTranslucent];
    [toolbar sizeToFit];
    
    //Create a fake button to maintain flexibleSpace between doneButton and nilButton. (Actually it moves done button to right side.
    UIBarButtonItem *nilButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    //Create a button to show on phoneNumber keyboard to resign it. Adding a selector to resign it.
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:target action:doneAction];
    
    XYSegmentedNextPrevious *segControl = [[XYSegmentedNextPrevious alloc] initWithTarget:target previousSelector:previousAction nextSelector:nextAction];
    //
    UIBarButtonItem *segButton = [[UIBarButtonItem alloc] initWithCustomView:segControl];
    
    //Adding button to toolBar.
    [toolbar setItems:[NSArray arrayWithObjects: segButton,nilButton,doneButton, nil]];
    //    [toolbar setItems:[NSArray arrayWithObjects: previousButton,nextButton,nilButton,doneButton, nil]];
    
    //Setting toolbar to textFieldPhoneNumber keyboard.
    [self setInputAccessoryView:toolbar];
    
    if (previousAction == nil || nextAction == nil)
    {
        [self setEnablePrevious:(previousAction != nil) next:(nextAction != nil)];
    }
}

- (void)setEnablePrevious:(BOOL)isPreviousEnabled next:(BOOL)isNextEnabled
{
    UIToolbar *inputView = (UIToolbar*)[self inputAccessoryView];
    
    if ([inputView isKindOfClass:[UIToolbar class]] && [[inputView items] count]>0)
    {
        UIBarButtonItem *barButtonItem = (UIBarButtonItem*)[[inputView items] objectAtIndex:0];
        
        if ([barButtonItem isKindOfClass:[UIBarButtonItem class]] && [barButtonItem customView] != nil)
        {
            UISegmentedControl *segmentedControl = (UISegmentedControl*)[barButtonItem customView];
            
            if ([segmentedControl isKindOfClass:[UISegmentedControl class]] && [segmentedControl numberOfSegments]>1)
            {
                [segmentedControl setEnabled:isPreviousEnabled forSegmentAtIndex:0];
                
                [segmentedControl setEnabled:isNextEnabled forSegmentAtIndex:1];
            }
        }
    }
}


@end

@implementation UITextView(ToolbarOnKeyboard)

#pragma mark - Toolbar on UIKeyboard
- (void)addDoneOnKeyboardWithTarget:(id)target action:(SEL)action
{
    //Creating a toolBar for phoneNumber keyboard
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [toolbar setBarStyle:UIBarStyleBlackTranslucent];
    [toolbar sizeToFit];
    
    //Create a button to show on phoneNumber keyboard to resign it. Adding a selector to resign it.
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:target action:action];
    
    //Create a fake button to maintain flexibleSpace between doneButton and nilButton. (Actually it moves done button to right side.
    UIBarButtonItem *nilButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    //Adding button to toolBar.
    [toolbar setItems:[NSArray arrayWithObjects: nilButton,doneButton, nil]];
    
    //Setting toolbar to textFieldPhoneNumber keyboard.
    [self setInputAccessoryView:toolbar];
}

- (void)addPreviousNextDoneOnKeyboardWithTarget:(id)target previousAction:(SEL)previousAction nextAction:(SEL)nextAction doneAction:(SEL)doneAction
{
    //Creating a toolBar for phoneNumber keyboard
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [toolbar setBarStyle:UIBarStyleBlackTranslucent];
    [toolbar sizeToFit];
    
    //Create a fake button to maintain flexibleSpace between doneButton and nilButton. (Actually it moves done button to right side.
    UIBarButtonItem *nilButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    //Create a button to show on phoneNumber keyboard to resign it. Adding a selector to resign it.
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:target action:doneAction];
    
    XYSegmentedNextPrevious *segControl = [[XYSegmentedNextPrevious alloc] initWithTarget:target previousSelector:previousAction nextSelector:nextAction];
    //
    UIBarButtonItem *segButton = [[UIBarButtonItem alloc] initWithCustomView:segControl];
    
    //Adding button to toolBar.
    [toolbar setItems:[NSArray arrayWithObjects: segButton,nilButton,doneButton, nil]];
    //    [toolbar setItems:[NSArray arrayWithObjects: previousButton,nextButton,nilButton,doneButton, nil]];
    
    //Setting toolbar to textFieldPhoneNumber keyboard.
    [self setInputAccessoryView:toolbar];
    
    if (previousAction == nil || nextAction == nil)
    {
        [self setEnablePrevious:(previousAction != nil) next:(nextAction != nil)];
    }
}

- (void)setEnablePrevious:(BOOL)isPreviousEnabled next:(BOOL)isNextEnabled
{
    UIToolbar *inputView = (UIToolbar*)[self inputAccessoryView];
    
    if ([inputView isKindOfClass:[UIToolbar class]] && [[inputView items] count]>0)
    {
        UIBarButtonItem *barButtonItem = (UIBarButtonItem*)[[inputView items] objectAtIndex:0];
        
        if ([barButtonItem isKindOfClass:[UIBarButtonItem class]] && [barButtonItem customView] != nil)
        {
            UISegmentedControl *segmentedControl = (UISegmentedControl*)[barButtonItem customView];
            
            if ([segmentedControl isKindOfClass:[UISegmentedControl class]] && [segmentedControl numberOfSegments]>1)
            {
                [segmentedControl setEnabled:isPreviousEnabled forSegmentAtIndex:0];
                
                [segmentedControl setEnabled:isNextEnabled forSegmentAtIndex:1];
            }
        }
    }
}


@end

@implementation XYSegmentedNextPrevious

- (id)initWithTarget:(id)target previousSelector:(SEL)pSelector nextSelector:(SEL)nSelector
{
    self = [super initWithItems:[NSArray arrayWithObjects:NSLocalizedString(@"Previous", @"前一项") , NSLocalizedString(@"Next", @"后一项") ,nil]];
    
    if (self)
    {
        //#ifndef __IPHONE_7_0
        [self setSegmentedControlStyle:UISegmentedControlStyleBar];
        //#endif
        
        [self setMomentary:YES];
        [self addTarget:self action:@selector(segmentedControlHandler:) forControlEvents:UIControlEventValueChanged];
        
        buttonTarget = target;
        previousSelector = pSelector;
        nextSelector = nSelector;
    }
    return self;
}

- (void)segmentedControlHandler:(XYSegmentedNextPrevious*)sender
{
    switch ([sender selectedSegmentIndex])
    {
        case 0:
        {
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[[buttonTarget class] instanceMethodSignatureForSelector:previousSelector]];
            invocation.target = buttonTarget;
            invocation.selector = previousSelector;
            [invocation invoke];
        }
            break;
        case 1:
        {
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[[buttonTarget class] instanceMethodSignatureForSelector:nextSelector]];
            invocation.target = buttonTarget;
            invocation.selector = nextSelector;
            [invocation invoke];
        }
        default:
            break;
    }
}

@end

