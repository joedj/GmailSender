#import <Preferences/Preferences.h>

#import "GmailAccount.h"

@interface AccountPSDetailController: PSListController
- (GmailAccount *)account;
@end
%group MobileMailSettings
%hook AccountPSDetailController
- (NSArray *)specifiers {
    NSMutableArray *specifiers = (NSMutableArray *)self->_specifiers;
    if (!specifiers) {
        specifiers = (NSMutableArray *)%orig;
        if ([self.account isKindOfClass:%c(GmailAccount)]) {
            NSUInteger specifierIndex = 0;
            for (PSSpecifier *specifier in specifiers) {
                specifierIndex++;
                if ([specifier.identifier isEqualToString:@"Username"]) {
                    break;
                }
            }
            PSSpecifier *specifier = [PSTextFieldSpecifier preferenceSpecifierNamed:@"From" target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:nil cell:PSEditTextCell edit:nil];
            [specifier setKeyboardType:UIKeyboardTypeEmailAddress autoCaps:UITextAutocapitalizationTypeNone autoCorrection:UITextAutocorrectionTypeDefault];
            [specifier setProperty:@"net.joedj.gmailsender" forKey:@"defaults"];
            [specifier setProperty:@"net.joedj.gmailsender" forKey:@"PostNotification"];
            [specifier setProperty:self.account.identifier forKey:@"key"];
            ((PSTextFieldSpecifier *)specifier).placeholder = @"example@domain.com";
            [specifiers insertObject:specifier atIndex:specifierIndex];
        }
    }
    return specifiers;
}
%end
%end

%hook NSBundle
- (BOOL)load {
    BOOL success = %orig;
    if (success && [self.bundleIdentifier isEqualToString:@"com.apple.mobilemail.settings"]) {
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            %init(MobileMailSettings);
        });
    }
    return success;
}
%end

%ctor {
    %init;
}
