//
//  CMRTaskManager.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/03/18.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

/*!
 * @header     CMRTaskManager
 * @discussion Application Task Manager
 */

#import <Cocoa/Cocoa.h>
#import "CMRTask.h"

/*!
 * @class       CMRTaskManager
 * @abstract    各タスクの進行状況を管理するマネージャ
 * @discussion  
 *
 * アプリケーションの各タスク（更新作業など）はCMRTaskManagerに登録する
 * ことでそれらの進行状況をユーザに視覚的に報告することができます。
 */

@interface CMRTaskManager : NSWindowController<CMRTask> {
	@private
	NSMutableArray					*_tasksInProgress;
    
    IBOutlet NSTableView *_tasksTableView; // 「動作状況」パネル用

	id<CMRTask>		m_currentTask;
}

+ (id)defaultManager;

- (void)taskWillStart:(id<CMRTask>)aTask;
- (void)taskDidFinish:(id<CMRTask>)aTask;

- (NSMutableArray *)tasksInProgress;

// For KVO
- (id<CMRTask>)currentTask;
- (void)setCurrentTask:(id<CMRTask>)aTask;
@end
