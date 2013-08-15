//
//  GSPreferences.m
//  noNvidia
//
//  Created by Cody Krieger on 9/26/10.
//  Copyright 2010 Cody Krieger. All rights reserved.
//

#import "GSPreferences.h"
#import "GSStartup.h"
#import "GSGPU.h"

// Unfortunately this value needs to stay misspelled unless there is a desire to
// migrate it to a correctly spelled version instead, since getting and setting
// the existing preferences depend on it.
#define kPowerSourceBasedSwitchingACMode        @"GPUSetting_ACAdaptor"
#define kPowerSourceBasedSwitchingBatteryMode   @"GPUSetting_Battery"

#define kShouldStartAtLoginKey                  @"shouldStartAtLogin"
#define kShouldUseImageIconsKey                 @"shouldUseImageIcons"
#define kShouldCheckForUpdatesOnStartupKey      @"shouldCheckForUpdatesOnStartup"
#define kShouldUsePowerSourceBasedSwitchingKey  @"shouldUsePowerSourceBasedSwitching"
#define kShouldUseSmartMenuBarIconsKey          @"shouldUseSmartMenuBarIcons"

// Why aren't we just using NSUserDefaults? Because it was unbelievably
// unreliable. This works all the time, no questions asked.
#define kPreferencesPlistPath [@"~/Library/Preferences/com.codykrieger.noNvidia-Preferences.plist" stringByExpandingTildeInPath]

@interface GSPreferences (Internal)
- (NSString *)_getPrefsPath;
@end

@implementation GSPreferences

@synthesize prefsDict = _prefsDict;

#pragma mark - Initializers

- (id)init
{
    if (!(self = [super init]))
        return nil;
    
    NSLog(@"Initializing GSPreferences...");
    [self setUpPreferences];
    
    return self;
}

+ (GSPreferences *)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static GSPreferences *_sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

#pragma mark - GSPreferences API

- (void)setUpPreferences
{
    NSLog(@"Loading preferences and defaults...");
    
    // Load the preferences dictionary from disk.
    _prefsDict = [[NSMutableDictionary alloc] initWithContentsOfFile:[self _getPrefsPath]];
    
    if (!_prefsDict) {
        // If preferences file doesn't exist, set the defaults.
        _prefsDict = [[NSMutableDictionary alloc] init];
        [self setDefaults];
    } else
        _prefsDict[kShouldStartAtLoginKey] = @([GSStartup existsInStartupItems]);
    
    // Ensure that application will be loaded at startup.
    if ([self shouldStartAtLogin])
        [GSStartup loadAtStartup:YES];
    
    // If an "integrated" image is available in our bundle, assume the user has
    // custom icons that we should use.
    _prefsDict[kShouldUseImageIconsKey] = @(!![[NSBundle mainBundle] pathForResource:@"integrated" ofType:@"png"]);
}

- (void)setDefaults
{
    NSLog(@"Setting initial defaults...");
    
    _prefsDict[kShouldCheckForUpdatesOnStartupKey] = @YES;
    _prefsDict[kShouldStartAtLoginKey] = @YES;
    _prefsDict[kShouldUsePowerSourceBasedSwitchingKey] = @NO;
    _prefsDict[kShouldUseSmartMenuBarIconsKey] = @NO;
    
    _prefsDict[kPowerSourceBasedSwitchingBatteryMode] = @(GSPowerSourceBasedSwitchingModeIntegrated);
    if ([GSGPU isLegacyMachine])
        _prefsDict[kPowerSourceBasedSwitchingACMode] = @(GSPowerSourceBasedSwitchingModeDiscrete);
    else
        _prefsDict[kPowerSourceBasedSwitchingACMode] = @(GSPowerSourceBasedSwitchingModeDynamic);
    
    [self savePreferences];
}

- (void)savePreferences
{
    NSLog(@"Writing preferences to disk...");
    
    if ([_prefsDict writeToFile:[self _getPrefsPath] atomically:YES])
        NSLog(@"Successfully wrote preferences to disk.");
    else
        NSLog(@"Failed to write preferences to disk. Permissions problem in ~/Library/Preferences?");
}

- (void)setBool:(BOOL)value forKey:(NSString *)key
{
    _prefsDict[key] = @(value);
    [self savePreferences];
}

- (BOOL)boolForKey:(NSString *)key
{
    return [_prefsDict[key] boolValue];
}

- (BOOL)shouldCheckForUpdatesOnStartup
{
    return [_prefsDict[kShouldCheckForUpdatesOnStartupKey] boolValue];
}

- (BOOL)shouldStartAtLogin
{
    return [_prefsDict[kShouldStartAtLoginKey] boolValue];
}

- (BOOL)shouldUsePowerSourceBasedSwitching
{
    return [_prefsDict [kShouldUsePowerSourceBasedSwitchingKey] boolValue];
}

- (BOOL)shouldUseImageIcons
{
    return [_prefsDict[kShouldUseImageIconsKey] boolValue];
}

- (BOOL)shouldUseSmartMenuBarIcons
{
    return [_prefsDict[kShouldUseSmartMenuBarIconsKey] boolValue];
}

- (GSPowerSourceBasedSwitchingMode)modeForACAdapter
{
    return [_prefsDict[kPowerSourceBasedSwitchingACMode] intValue];
}

- (GSPowerSourceBasedSwitchingMode)modeForBattery
{
    return [_prefsDict[kPowerSourceBasedSwitchingBatteryMode] intValue];
}

#pragma mark - NSWindowDelegate protocol

- (void)windowWillClose:(NSNotification *)notification
{
    [self savePreferences];
}

@end

#pragma mark - Private helpers

@implementation GSPreferences (Internal)

- (NSString *)_getPrefsPath
{
    return kPreferencesPlistPath;
}

@end
