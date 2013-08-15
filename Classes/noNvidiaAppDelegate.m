//
//  noNvidiaAppDelegate.m
//  noNvidia
//
//  Created by Cody Krieger on 4/22/10.
//  Copyright 2010 Cody Krieger. All rights reserved.
//

#import "noNvidiaAppDelegate.h"
#import "GSProcess.h"
#import "GSMux.h"

@implementation noNvidiaAppDelegate

#pragma mark - Initialization

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Initialize the preferences object and set default preferences if this is
    // a first-time run.
    _prefs = [GSPreferences sharedInstance];

    // Attempt to open a connection to AppleGraphicsControl.
    if (![GSMux switcherOpen]) {
        NSLog(@"Can't open connection to AppleGraphicsControl. This probably isn't a noNvidia-compatible machine.");
    } else {
        NSLog(@"GPUs present: %@", [GSGPU getGPUNames]);
        NSLog(@"Integrated GPU name: %@", [GSGPU integratedGPUName]);
        NSLog(@"Discrete GPU name: %@", [GSGPU discreteGPUName]);
    }

    // Now accepting GPU change notifications! Apply at your nearest GSGPU today.
    [GSGPU registerForGPUChangeNotifications:self];
    [GSMux setMode:GSSwitcherModeForceIntegrated];
}

- (void)workspaceWillPowerOff:(NSNotification *)aNotification
{
    // Selector called in response to application termination notification from
    // NSWorkspace.
    NSLog(@"NSWorkspaceWillPowerOff notification received. Terminating application.");
    [[NSApplication sharedApplication] terminate:self];
}

#pragma mark - GSGPUDelegate protocol

- (void)GPUDidChangeTo:(GSGPUType)gpu
{
    NSLog(@"Changed to %s.", gpu == GSGPUTypeIntegrated ? "integrated" : "discreet");
}

@end
