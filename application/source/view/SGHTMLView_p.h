//:SGHTMLView_p.h
#import "SGHTMLView.h"
#import "CocoMonar_Prefix.h"

#import "SGLinkCommand.h"
#import "SGDownloadLinkCommand.h"
#import "CMRMessageAttributesTemplate.h"
#import <SGAppKit/SGAppKit.h>


#define kLocalizableFile	@"HTMLView"
#define kLinkStringKey		@"Link"
#define kCopyLinkStringKey		@"Copy Link"
#define kOpenLinkStringKey		@"Open Link"
#define kPreviewLinkStringKey	@"Preview Link"
#define kDownloadLinkStringKey	@"Download Link"


@interface SGHTMLView(Link)
- (NSTrackingArea *)visibleArea;

- (void)resetCursorRectsImp;
- (void)responseMouseEvent:(NSEvent *)theEvent mouseEntered:(BOOL)isMouseEntered;
- (void)updateAnchoredRectsInBounds:(NSRect)aBounds forAttribute:(NSString *)attributeName;
- (void)updateAnchoredRectsForIDAttributesInBounds:(NSRect)aBounds;

- (void)resetTrackingVisibleRect;

- (void)addLinkTrackingArea:(NSRect)aRect link:(id)aLink attributeName:(NSString *)name;
- (void)addLinkTrackingArea:(NSRect)aRect link:(id)aLink isOnIDField:(BOOL)onIDField;
- (void)removeAllLinkTrackingRects;
@end


@interface SGHTMLView(ResponderExtensions)
- (NSMenuItem *)commandItemWithLink:(id)aLink command:(Class)aFunctorClass title:(NSString *)aTitle;
- (NSMenu *)linkMenuWithLink:(id)aLink;

- (BOOL)validateLinkByFiltering:(id)aLink;

// Available in Twincam Angel and later.
- (NSArray *)linksArrayForRange:(NSRange)range_;
- (NSArray *)previewlinksArrayForRange:(NSRange)range_;

- (void)pushCloseHandCursorIfNeeded;
- (void)commandMouseDragged:(NSEvent *)theEvent;
- (void)commandMouseUp:(NSEvent *)theEvent;
- (void)commandMouseDown:(NSEvent *)theEvent;
@end


@interface SGHTMLView(DelegateSupport)
- (void)mouseEventInVisibleRect:(NSEvent *)theEvent entered:(BOOL)mouseEntered;

- (void)processMouseOverEvent:(NSEvent *)theEvent trackingArea:(NSTrackingArea *)area mouseEntered:(BOOL)mouseEntered;

- (BOOL)shouldHandleContinuousMouseDown:(NSEvent *)theEvent;
- (BOOL)handleContinuousMouseDown:(NSEvent *)theEvent;
@end
