#import "MailAccount.h"

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

static NSArray *emailAddresses(MailAccount *account, NSArray *realAddresses) {
    NSArray *fromAddresses = addresses_for_account(account.identifier);
    if (fromAddresses.count) {
        NSMutableArray *newAddresses = [[NSMutableArray alloc] init];
        NSMutableSet *seenAddresses = [[NSMutableSet alloc] init];
        for (NSString *address in [fromAddresses arrayByAddingObjectsFromArray:realAddresses]) {
            if (address.length && ![seenAddresses containsObject:address]) {
                [newAddresses addObject:address];
                [seenAddresses addObject:address];
            }
        }
        return newAddresses;
    }
    return realAddresses;
}

@interface GmailAccount: MailAccount
@end
%group IMAP
%hook GmailAccount
- (NSArray *)emailAddresses {
    return emailAddresses(self, %orig);
}
%end
%end

%hook MailAccount

+ (void)initialize {
    if (self == %c(GmailAccount)) {
        %init(IMAP);
    }
    %orig;
}

- (NSArray *)emailAddresses {
    return emailAddresses(self, %orig);
}

%end

%ctor {
    lock = [[NSObject alloc] init];
    %init;
}
