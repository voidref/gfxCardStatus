//
//  GSPreferences.h
//  noNvidia
//
//  Created by Cody Krieger on 9/26/10.
//  Copyright 2010 Cody Krieger. All rights reserved.
//

typedef enum {
    GSPowerSourceBasedSwitchingModeIntegrated = 0,
    GSPowerSourceBasedSwitchingModeDiscrete = 1,
    GSPowerSourceBasedSwitchingModeDynamic = 2
} GSPowerSourceBasedSwitchingMode;

@interface GSPreferences : NSObject <NSWindowDelegate> {
    NSMutableDictionary *_prefsDict;
    
    NSNumber *yesNumber;
    NSNumber *noNumber;
}

@property (strong) NSMutableDictionary *prefsDict;

- (void)setUpPreferences;
- (void)setDefaults;
- (void)savePreferences;

- (BOOL)shouldStartAtLogin;

- (void)setBool:(BOOL)value forKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;

- (void)savePreferences;

+ (GSPreferences *)sharedInstance;

@end
