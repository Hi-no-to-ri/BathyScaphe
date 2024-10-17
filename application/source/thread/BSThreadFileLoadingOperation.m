//
//  BSThreadFileLoadingOperation.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2013/11/22.
//
//

#import "BSThreadFileLoadingOperation.h"
#import "CMRThreadDictReader.h"

@implementation BSThreadFileLoadingOperation
@synthesize attrDict = m_attrDict;

- (id)initWithURL:(NSURL *)url
{
    if (self = [super initWithThreadReader:nil]) {
        m_fileURL = [url copy];
        m_attrDict = nil;
    }
    return self;
}

- (void)dealloc
{
    [m_fileURL release];
    [m_attrDict release];
    [super dealloc];
}

- (void)main
{
    CMRThreadDictReader *reader;
    
    reader = [CMRThreadDictReader readerWithContentsOfFile:[m_fileURL path]];
    [reader setNextMessageIndex:0];
    
    if (self.isCancelled) {
        return;
    }
    
    m_attrDict = [[reader threadAttributes] copy];
    if (self.isCancelled) {
        return;
    }
    
    [self.delegate threadAttributesDidLoadFromFile:self];
    
    m_reader = [reader retain];
    m_countedSet = [[NSCountedSet alloc] init];

    if (self.isCancelled) {
        return;
    }

    [super main];
}

- (id<BSThreadFileLoadingOperationDelegate>)delegate
{
    return (id<BSThreadFileLoadingOperationDelegate>)[super delegate];
}

- (void)setDelegate:(id<BSThreadFileLoadingOperationDelegate>)aDelegate
{
    [super setDelegate:aDelegate];
}
@end
