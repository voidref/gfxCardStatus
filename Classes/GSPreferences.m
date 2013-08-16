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

#define kShouldStartAtLoginKey                  @"shouldStartAtLogin"

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
    
}

- (void)setDefaults
{
    NSLog(@"Setting initial defaults...");
    
    _prefsDict[kShouldStartAtLoginKey] = @YES;
    
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

- (BOOL)shouldStartAtLogin
{
    return [_prefsDict[kShouldStartAtLoginKey] boolValue];
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
