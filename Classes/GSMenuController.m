//
//  GSMenuController.m
//  gfxCardStatus
//
//  Created by Cody Krieger on 6/12/12.
//  Copyright (c) 2012 Cody Krieger. All rights reserved.
//

#import "GSMenuController.h"
#import "GeneralPreferencesViewController.h"
#import "AdvancedPreferencesViewController.h"
#import "GSGPU.h"
#import "GSMux.h"
#import "GSNotifier.h"
#import "GSProcess.h"

#define kImageIconIntegratedName    @"integrated"
#define kImageIconDiscreteName      @"discrete"
#define kImageIconOpenSuffix        @"-white"

#define kShouldUseSmartMenuBarIconsKeyPath @"prefsDict.shouldUseSmartMenuBarIcons"

@interface GSMenuController (Internal)
- (void)_updateProcessList;
@end

@implementation GSMenuController

@synthesize delegate;

@synthesize statusMenu;

@synthesize versionItem;
@synthesize updateItem;
@synthesize preferencesItem;
@synthesize quitItem;
@synthesize visitWebsiteItem;
@synthesize currentCard;
@synthesize currentPowerSource;
@synthesize switchGPUs;
@synthesize integratedOnly;
@synthesize discreteOnly;
@synthesize dynamicSwitching;
@synthesize processesSeparator;
@synthesize dependentProcesses;
@synthesize processList;

@synthesize menuIsOpen;

#pragma mark - Initializers

- (id)init
{
    if (!(self = [super init]))
        return nil;
    
    _prefs = [GSPreferences sharedInstance];
    
    return self;
}

#pragma mark - GSMenuController API

- (void)setupMenu
{
    [statusMenu setDelegate:self];
    
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setMenu:statusMenu];
    [_statusItem setHighlightMode:YES];
    
    BOOL isLegacyMachine = [GSGPU isLegacyMachine];
    [switchGPUs setHidden:!isLegacyMachine];
    [integratedOnly setHidden:isLegacyMachine];
    [discreteOnly setHidden:isLegacyMachine];
    [dynamicSwitching setHidden:isLegacyMachine];
    
    [self updateMenu];
}

- (void)updateMenu
{
    NSLog(@"Updating status...");

    BOOL isUsingIntegrated = [GSMux isUsingIntegratedGPU];

    NSString *gpuString = (isUsingIntegrated ? [GSGPU integratedGPUName] : [GSGPU discreteGPUName]);

    if (![GSGPU isLegacyMachine]) {
        BOOL dynamic = [GSMux isUsingDynamicSwitching];
        BOOL isOnIntegratedOnly = [GSMux isOnIntegratedOnlyMode];

        NSLog(@"Using dynamic switching?: %d", dynamic);
        NSLog(@"Using old-style switching policy?: %d", [GSMux isUsingOldStyleSwitchPolicy]);

        [integratedOnly setState:(isOnIntegratedOnly && !dynamic) ? NSOnState : NSOffState];
        [discreteOnly setState:(!isOnIntegratedOnly && !dynamic) ? NSOnState : NSOffState];
        [dynamicSwitching setState:dynamic ? NSOnState : NSOffState];
    }

    [currentCard setTitle:[Str(@"Card") stringByReplacingOccurrencesOfString:@"%%" withString:gpuString]];

    if (isUsingIntegrated)
        NSLog(@"%@ in use. Sweet deal! More battery life.", [GSGPU integratedGPUName]);
    else
        NSLog(@"%@ in use. Bummer! Less battery life for you.", [GSGPU discreteGPUName]);

    if (!isUsingIntegrated)
        [self _updateProcessList];
}

#pragma mark - UI Actions

- (IBAction)openAbout:(id)sender
{
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)openPreferences:(id)sender
{
    if (!_preferencesWindowController) {
        _preferencesWindowController = [[PreferencesWindowController alloc] init];
        
        NSArray *modules = @[[[GeneralPreferencesViewController alloc] init], 
                            [[AdvancedPreferencesViewController alloc] init]];
        
        [_preferencesWindowController setModules:modules];
    }
    
    [_preferencesWindowController.window center];
    [_preferencesWindowController.window makeKeyAndOrderFront:self];
    [_preferencesWindowController.window setOrderedIndex:0];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)quit:(id)sender
{
    [[NSApplication sharedApplication] terminate:self];
}

- (IBAction)setMode:(id)sender
{
    // For legacy machines.
    if (sender == switchGPUs) {
        NSLog(@"Switching GPUs...");
        [GSMux setMode:GSSwitcherModeToggleGPU];
        return;
    }

    // Don't go any further if the user clicked on an already-selected item.
    if ([sender state] == NSOnState) return;

    BOOL retval = NO;

    if (sender == integratedOnly) {
        NSArray *taskList = [GSProcess getTaskList];
        if (taskList.count > 0) {
            NSLog(@"Not setting Integrated Only because of dependencies list items: %@", taskList);

            NSMutableArray *taskNames = [[NSMutableArray alloc] init];
            for (NSDictionary *dict in taskList) {
                NSString *taskName = dict[kTaskItemName];
                [taskNames addObject:taskName];
            }

            [GSNotifier showCantSwitchToIntegratedOnlyMessage:taskNames];
            return;
        }

        NSLog(@"Setting Integrated Only...");
        retval = [GSMux setMode:GSSwitcherModeForceIntegrated];
    }

    if (sender == discreteOnly) { 
        NSLog(@"Setting Discrete Only...");
        retval = [GSMux setMode:GSSwitcherModeForceDiscrete];
    }

    if (sender == dynamicSwitching) {
        NSLog(@"Setting Dynamic Switching...");
        retval = [GSMux setMode:GSSwitcherModeDynamicSwitching];
    }

    // Only change status in case of GPU switch success.
    if (retval) {
        [integratedOnly setState:(sender == integratedOnly ? NSOnState : NSOffState)];
        [discreteOnly setState:(sender == discreteOnly ? NSOnState : NSOffState)];
        [dynamicSwitching setState:(sender == dynamicSwitching ? NSOnState : NSOffState)];
    }
}

#pragma mark - NSMenuDelegate protocol

- (void)menuNeedsUpdate:(NSMenu *)menu
{
    [self _updateProcessList];
}

- (void)menuWillOpen:(NSMenu *)menu
{
    self.menuIsOpen = YES;
}

- (void)menuDidClose:(NSMenu *)menu
{
    self.menuIsOpen = NO;
}

@end

@implementation GSMenuController (Internal)

- (void)_localizeMenu
{
    NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    [versionItem setTitle:[Str(@"About") stringByReplacingOccurrencesOfString:@"%%" withString:version]];
    NSArray *localized = @[updateItem, preferencesItem,
                          quitItem, switchGPUs, integratedOnly, discreteOnly, 
                          dynamicSwitching, dependentProcesses, processList];
    for (NSButton *loc in localized)
        [loc setTitle:Str([loc title])];
}

- (void)_updateProcessList
{
    for (NSMenuItem *menuItem in [statusMenu itemArray]) {
        if ([menuItem indentationLevel] > 0 && ![menuItem isEqual:processList])
            [statusMenu removeItem:menuItem];
    }
    
    BOOL isUsingIntegrated = [GSMux isUsingIntegratedGPU];

    BOOL hide = isUsingIntegrated || [GSGPU isLegacyMachine];
    [processList setHidden:hide];
    [processesSeparator setHidden:hide];
    [dependentProcesses setHidden:hide];

    // If we're using a 9400M/9600M GT model, or if we're on the integrated GPU,
    // no need to display/update the dependencies list.
    if (hide)
        return;
    
    NSLog(@"Updating process list...");
    
    NSArray *processes = [GSProcess getTaskList];
    
    [processList setHidden:([processes count] > 0)];
    
    for (NSDictionary *dict in processes) {
        NSString *taskName = dict[kTaskItemName];
        NSString *pid = dict[kTaskItemPID];
        NSString *title = [NSString stringWithString:taskName];
        if (![pid isEqualToString:@""])
            title = [title stringByAppendingFormat:@", PID: %@", pid];
        
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title 
                                                      action:nil 
                                               keyEquivalent:@""];
        [item setIndentationLevel:1];
        [statusMenu insertItem:item 
                       atIndex:([statusMenu indexOfItem:processList] + 1)];
    }
}

@end
