//
//  CMRTaskManager.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/03/18.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRTaskManager.h"
#import "CocoMonar_Prefix.h"
#import "BSTaskItemValueTransformer.h"

#define APP_TASK_MANAGER_NIB_NAME         @"CMRTaskManager"

@interface CMRTaskManager()
- (void)addTaskInProgress:(id<CMRTask>)aTask;
- (void)removeTask:(id<CMRTask>)aTask;
- (BOOL)shouldRegisterTask:(id<CMRTask>)aTask;

- (NSTableView *)tasksTableView;
@end


@implementation CMRTaskManager
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(defaultManager);

- (id)init
{
    if (self = [self initWithWindowNibName:APP_TASK_MANAGER_NIB_NAME]) {
        id transformer = [[[BSTaskItemValueTransformer alloc] init] autorelease];
        [NSValueTransformer setValueTransformer:transformer forName:@"BSTaskItemValueTransformer"];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    m_currentTask = nil;
    
    [_tasksInProgress release];

    [super dealloc];
}

- (void)awakeFromNib
{
    [(NSPanel *)[self window] setFloatingPanel:NO];
    [(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];
}

- (IBAction)showWindow:(id)sender
{
    // toggle-Action : すでにパネルが表示されているときは、パネルを閉じる
    if (![self isWindowLoaded] || ![[self window] isVisible]) {
        [super showWindow:sender];
    } else {
        [[self window] orderOut:sender];
    }
}

- (void)taskWillStart:(id<CMRTask>)aTask
{
    if ([NSThread isMainThread]) {
        [self addTaskInProgress:aTask];
    } else {
        [self performSelectorOnMainThread:_cmd withObject:aTask waitUntilDone:NO];
    }
}

- (void)taskDidFinish:(id<CMRTask>)aTask
{
    if ([NSThread isMainThread]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey]) {
            NSLog(@"** USER DEBUG ** CurrentTask: %@ Finished Task: %@", [self currentTask], aTask);
        }

        if ([self currentTask] == aTask) {
            [self setCurrentTask:nil];
        }
        [self removeTask:aTask];
    } else {
        [self performSelectorOnMainThread:_cmd withObject:aTask waitUntilDone:NO];
    }
}

- (NSMutableArray *)tasksInProgress
{
    if (!_tasksInProgress) {
        _tasksInProgress = [[NSMutableArray alloc] init];
    }
    return _tasksInProgress;
}

#pragma mark CMRTask protocol
- (NSString *)identifier
{
    return nil;
}

- (NSString *)title
{
    return nil;
}

- (NSString *)message
{
    return nil;
}

- (BOOL)isInProgress
{
    return ([[self tasksInProgress] count] > 0);
}

- (double)amount
{
    return -1;
}

- (IBAction)cancel:(id)sender
{
    [[[self tasksInProgress] lastObject] cancel:sender];
}

#pragma mark For KVO
- (id<CMRTask>)currentTask
{
    return m_currentTask;
}

- (void)setCurrentTask:(id<CMRTask>)aTask
{
    m_currentTask = aTask;
}

#pragma mark Private
- (void)addTaskInProgress:(id<CMRTask>)aTask
{
    if (![self shouldRegisterTask:aTask]) {
        return;
    }
    
    [self willChangeValueForKey:@"tasksInProgress"];
    [[self tasksInProgress] addObject:aTask];
    [self didChangeValueForKey:@"tasksInProgress"];
    [self setCurrentTask:aTask];
}

- (void)removeTask:(id<CMRTask>)aTask
{
    [self willChangeValueForKey:@"tasksInProgress"];
    [[self tasksInProgress] removeObject:aTask];
    [self didChangeValueForKey:@"tasksInProgress"];
}

- (BOOL)shouldRegisterTask:(id<CMRTask>)aTask
{
    return ([aTask identifier] != nil);
}

- (NSTableView *)tasksTableView
{
    return _tasksTableView;
}
@end
