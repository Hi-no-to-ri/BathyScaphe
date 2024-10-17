//
//  BSLPSPreviewerItem.h
//  PreviewerSelector
//
//  Created by masakih on 09/02/14.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@interface BSLPSPreviewerItem : NSObject <NSCopying, NSCoding>
{
	id _previewer;	// コピーしない。 codingしない。
	NSString *_identifier;
	NSString *_displayName;
	NSString *_path;
	NSString *_version;
	BOOL _tryCheck;
	BOOL _displayInMenu;
}

- (id)initWithIdentifier:(NSString *)identifier;

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, retain) id previewer;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *version;
@property (getter=isTryCheck) BOOL tryCheck;
@property (getter=isDisplayInMenu) BOOL displayInMenu;

@property (readonly) NSString *copyright;
@property (readonly) BOOL hasPreviewPanel;
@property (readonly) BOOL hasPreferencePanel;
@property (readonly) NSImage *icon;

@end
