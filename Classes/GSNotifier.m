//
//  GSNotifier.m
//  gfxCardStatus
//
//  Created by Cody Krieger on 6/12/12.
//  Copyright (c) 2012 Cody Krieger. All rights reserved.
//

#import "GSNotifier.h"
#import "GSMux.h"
#import "GSPreferences.h"

#define kIntegratedOnlyMessageExplanationURL [kApplicationWebsiteURL stringByAppendingString:@"/switching.html#integrated-only-mode-limitations"]

static NSString *_lastMessage = nil;

@interface GSNotifier () <NSUserNotificationCenterDelegate>
@end

@implementation GSNotifier

#pragma mark - Initializers

+ (GSNotifier *)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static GSNotifier *_sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (id)init
{
    if (!(self = [super init]))
        return nil;

    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;

    return self;
}

#pragma mark - GSNotifier API


+ (void)showUnsupportedMachineMessage
{
    NSAlert *alert = [NSAlert alertWithMessageText:Str(@"UnsupportedMachine")
                                     defaultButton:Str(@"OhISee")
                                   alternateButton:nil 
                                       otherButton:nil 
                         informativeTextWithFormat:@""];
    [alert runModal];
}

+ (void)showCantSwitchToIntegratedOnlyMessage:(NSArray *)taskList
{
    NSString *messageKey = [NSString stringWithFormat:@"Can'tSwitchToIntegratedOnly%@", (taskList.count > 1 ? @"Plural" : @"Singular")];

    NSMutableString *descriptionText = [[NSMutableString alloc] init];
    for (NSString *taskName in taskList)
        [descriptionText appendFormat:@"%@\n", taskName];

    NSAlert *alert = [NSAlert alertWithMessageText:Str(messageKey)
                                     defaultButton:@"OK"
                                   alternateButton:@"Why?"
                                       otherButton:nil
                         informativeTextWithFormat:@"%@", descriptionText];

    if ([alert runModal] == NSAlertAlternateReturn) {}
}

+ (BOOL)notificationCenterIsAvailable
{
    return !!NSClassFromString(@"NSUserNotification");
}

#pragma mark - GrowlApplicationBridgeDelegate protocol

- (NSDictionary *)registrationDictionaryForGrowl
{
    return [NSDictionary dictionaryWithContentsOfFile:
            [[NSBundle mainBundle] pathForResource:@"Growl Registration Ticket" 
                                            ofType:@"growlRegDict"]];
}

#pragma mark - NSUserNotificationCenterDelegate protocol

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    [center removeDeliveredNotification:notification];
}


@end
