//
//  OrionTouchBarPatch-Bridging-Header.h
//  OrionTouchBarPatch
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

extern void DFRElementSetControlStripPresenceForIdentifier(NSTouchBarItemIdentifier identifier, BOOL presence);
extern void DFRSystemModalShowsCloseBoxWhenFrontMost(BOOL show);

@interface NSTouchBarItem (OrionTouchBarPrivate)
+ (void)addSystemTrayItem:(NSTouchBarItem *)item;
+ (void)removeSystemTrayItem:(NSTouchBarItem *)item;
@end

@interface NSTouchBar (OrionTouchBarPrivate)
+ (void)presentSystemModalTouchBar:(NSTouchBar *)touchBar
        systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier;
+ (void)presentSystemModalTouchBar:(NSTouchBar *)touchBar
                         placement:(long long)placement
        systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier;
+ (void)dismissSystemModalTouchBar:(NSTouchBar *)touchBar;
@end

NS_ASSUME_NONNULL_END
