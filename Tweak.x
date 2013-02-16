#import "GmailAccount.h"

static NSObject *lock;
static NSDictionary *settings;

static void toggle(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    @synchronized (lock) {
        settings = nil;
    }
}

static NSArray *addresses_for_account(NSString *identifier) {
    @synchronized (lock) {
        if (!settings) {
            static dispatch_once_t once;
            dispatch_once(&once, ^{
                CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &toggle, CFSTR("net.joedj.gmailsender"), NULL, 0);
            });
            settings = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/net.joedj.gmailsender.plist"] ?: @{};
        }
        return [settings[identifier] componentsSeparatedByString:@" "];
    }
}

%group IMAP
%hook GmailAccount
- (NSArray *)emailAddresses {
    NSMutableArray *addresses = (NSMutableArray *)%orig;
    NSArray *fromAddresses = addresses_for_account(self.identifier);
    if (fromAddresses.count) {
        addresses = [NSMutableArray arrayWithArray:addresses];
        NSUInteger fromAddressIndex = 0;
        for (NSString *address in fromAddresses) {
            if (address.length && ![addresses containsObject:address]) {
                [addresses insertObject:address atIndex:fromAddressIndex++];
            }
        }
    }
    return addresses;
}
%end
%end

%hook NSBundle
- (BOOL)load {
    BOOL success = %orig;
    if (success && [self.bundleIdentifier isEqualToString:@"com.apple.IMAP"]) {
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            %init(IMAP);
        });
    }
    return success;
}
%end

%ctor {
    lock = [[NSObject alloc] init];
    %init;
}
