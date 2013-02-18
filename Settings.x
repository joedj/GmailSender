#import <Preferences/Preferences.h>

#import "MailAccount.h"

@interface PSListController ()
- (MailAccount *)account;
@end

static void insertSpecifier(PSListController *controller, NSMutableArray *specifiers, NSUInteger index) {
    PSTextFieldSpecifier *specifier = [PSTextFieldSpecifier preferenceSpecifierNamed:@"From" target:controller set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:nil cell:PSEditTextCell edit:nil];
    [specifier setKeyboardType:UIKeyboardTypeEmailAddress autoCaps:UITextAutocapitalizationTypeNone autoCorrection:UITextAutocorrectionTypeDefault];
    [specifier setProperty:@"net.joedj.gmailsender" forKey:@"defaults"];
    [specifier setProperty:@"net.joedj.gmailsender" forKey:@"PostNotification"];
    [specifier setProperty:controller.account.identifier forKey:@"key"];
    specifier.placeholder = @"example@domain.com";
    [specifiers insertObject:specifier atIndex:index];
}

@interface AccountPSDetailController: PSListController
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
            insertSpecifier(self, specifiers, specifierIndex);
        }
    }
    return specifiers;
}
%end
%end

@interface ASSettingsAccountController: PSListController
@end
%group DataAccessUI
%hook ASSettingsAccountController
- (NSArray *)specifiers {
    NSMutableArray *specifiers = (NSMutableArray *)self->_specifiers;
    if (!specifiers) {
        specifiers = [NSMutableArray arrayWithArray:%orig];
        self->_specifiers = specifiers;
        NSUInteger specifierIndex = 0;
        for (PSSpecifier *specifier in specifiers) {
            specifierIndex++;
            if ([specifier.identifier isEqualToString:@"EMAIL"]) {
                break;
            }
        }
        insertSpecifier(self, specifiers, specifierIndex);
    }
    return specifiers;
}
%end
%end

%hook PSListController
+ (void)initialize {
    if (self == %c(AccountPSDetailController)) {
        %init(MobileMailSettings);
    } else if (self == %c(ASSettingsAccountController)) {
        %init(DataAccessUI);
    }
    %orig;
}
%end

%ctor {
    %init;
}
