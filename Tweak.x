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
        return [settings[identifier] componentsSeparatedByString:@" "] ?: @[];
    }
}

%group IMAP
%hook GmailAccount
- (NSArray *)emailAddresses {
    NSArray *addresses = %orig;
    NSArray *fromAddresses = addresses_for_account(self.identifier);
    if (fromAddresses.count) {
        NSMutableArray *newAddresses = [[NSMutableArray alloc] init];
        NSMutableSet *seenAddresses = [[NSMutableSet alloc] init];
        for (NSString *address in [fromAddresses arrayByAddingObjectsFromArray:addresses]) {
            if (address.length && ![seenAddresses containsObject:address]) {
                [newAddresses addObject:address];
                [seenAddresses addObject:address];
            }
        }
        addresses = newAddresses;
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
