//
//  gfxCardStatusAppDelegate.m
//  gfxCardStatus
//
//  Created by Cody Krieger on 4/22/10.
//  Copyright 2010 Cody Krieger. All rights reserved.
//

#import "gfxCardStatusAppDelegate.h"
#import "GeneralPreferencesViewController.h"
#import "AdvancedPreferencesViewController.h"
#import "GSProcess.h"
#import "GSMux.h"
#import "GSNotifier.h"

@implementation gfxCardStatusAppDelegate

@synthesize menuController;

#pragma mark - Initialization

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Initialize the preferences object and set default preferences if this is
    // a first-time run.
    _prefs = [GSPreferences sharedInstance];

    // Attempt to open a connection to AppleGraphicsControl.
    if (![GSMux switcherOpen]) {
        NSLog(@"Can't open connection to AppleGraphicsControl. This probably isn't a gfxCardStatus-compatible machine.");
        
        [menuController quit:self];
    } else {
        NSLog(@"GPUs present: %@", [GSGPU getGPUNames]);
        NSLog(@"Integrated GPU name: %@", [GSGPU integratedGPUName]);
        NSLog(@"Discrete GPU name: %@", [GSGPU discreteGPUName]);
    }

    // Now accepting GPU change notifications! Apply at your nearest GSGPU today.
    [GSGPU registerForGPUChangeNotifications:self];
    [GSMux setMode:GSSwitcherModeForceIntegrated];
}

#pragma mark - Termination Notifications

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Set the machine to dynamic switching before shutdown to avoid machine restarting
    // stuck in a forced GPU mode.
//    if (![GSGPU isLegacyMachine])
//        [GSMux setMode:GSSwitcherModeDynamicSwitching];

    NSLog(@"Termination notification received.");
}

- (void)workspaceWillPowerOff:(NSNotification *)aNotification
{
    // Selector called in response to application termination notification from
    // NSWorkspace. Also implemented to avoid the machine shuting down in a forced
    // GPU state.
    [[NSApplication sharedApplication] terminate:self];
    NSLog(@"NSWorkspaceWillPowerOff notification received. Terminating application.");
}

#pragma mark - GSGPUDelegate protocol

- (void)GPUDidChangeTo:(GSGPUType)gpu
{
    NSLog(@"Changed to %s.", gpu == GSGPUTypeIntegrated ? "integrated" : "discreet");
}

@end
