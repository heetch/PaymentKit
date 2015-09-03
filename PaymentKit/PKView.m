//
//  PKPaymentField.m
//  PKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#define RGB(r,g,b) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1.0f]
#define DarkGreyColor RGB(0,0,0)
#define RedColor RGB(253,0,17)
#define DefaultBoldFont [UIFont boldSystemFontOfSize:17]

#define kPKViewPlaceholderViewAnimationDuration 0.25

#define kPKViewCardExpiryFieldStartX 84 + 200
#define kPKViewCardCVCFieldStartX 177 + 200

#define kPKViewCardExpiryFieldEndX 84
#define kPKViewCardCVCFieldEndX 177

#define kNoFocusColor RGB(174, 174, 174)
#define kInvalidColor RGB(249, 111, 123)
#define kValidColor RGB(71, 192, 194)


static NSString *const kPKLocalizedStringsTableName = @"PaymentKit";
static NSString *const kPKOldLocalizedStringsTableName = @"STPaymentLocalizable";

#import "PKView.h"
#import "PKTextField.h"

@interface PKView () <PKTextFieldDelegate, CardIOPaymentViewControllerDelegate> {
@private
    BOOL _isInitialState;
    BOOL _isValidState;
}

@property (nonatomic, strong, readwrite) UIView *validView;

@property (nonatomic, readonly, assign) UIResponder *firstResponderField;
@property (nonatomic, readonly, assign) PKTextField *firstInvalidField;
@property (nonatomic, readonly, assign) PKTextField *nextFirstResponder;

- (void)setup;
- (void)setupPlaceholderView;
- (void)setupCardNumberField;
- (void)setupCardExpiryField;
- (void)setupCardCVCField;

- (void)pkTextFieldDidBackSpaceWhileTextIsEmpty:(PKTextField *)textField;

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardNumberFieldShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardExpiryShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardCVCShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;

@property (nonatomic) PKCardNumber *cardNumber;
@property (nonatomic) PKCardExpiry *cardExpiry;
@property (nonatomic) PKCardCVC *cardCVC;
@property (nonatomic) PKAddressZip *addressZip;
@end

#pragma mark -

@implementation PKView

- (id)initWithFont:(UIFont *)font fontColor:(UIColor *)fontColor noFocusColor:(UIColor *)noFocusColor invalidColor:(UIColor *)invalidColor validColor:(UIColor *)validColor placeholderColor:(UIColor *)placeholderColor {
    self = [super init];
    if (self) {
        self.viewFont = font;
        self.fontColor = fontColor;
        self.noFocusColor = noFocusColor;
        self.invalidColor = invalidColor;
        self.validColor = validColor;
        self.placeholderColor = placeholderColor;
        [self setup];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)setup
{
    if (!self.noFocusColor) {
        self.noFocusColor = kNoFocusColor;
    }
    if (!self.fontColor) {
        self.fontColor = self.noFocusColor;
    }
    if (!self.invalidColor) {
        self.invalidColor = kInvalidColor;
    }
    if (!self.validColor) {
        self.validColor = kValidColor;
    }

    if (!self.viewFont) {
        self.viewFont = DefaultBoldFont;
    }

    if (!self.placeholderColor) {
        self.placeholderColor = [UIColor lightGrayColor];
    }

    _isInitialState = YES;
    _isValidState = NO;

    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, 290, 46);
    self.backgroundColor = [UIColor clearColor];

    self.validView = [[UIView alloc] initWithFrame:CGRectMake(self.frame.origin.x, self.frame.size.height - 1.0f, self.frame.size.width, 1.0f)];
    self.validView.backgroundColor = self.noFocusColor;
    [self addSubview:self.validView];



    [self.validView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0.0-[validView]-0.0-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:@{@"validView":self.validView}]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[validView(1.0)]-0.0-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:@{@"validView":self.validView}]];


    self.innerView = [[UIView alloc] initWithFrame:CGRectMake(40, 12, self.frame.size.width - 40, 20)];
    self.innerView.clipsToBounds = YES;

    [self setupPlaceholderView];
    [self setupScanButton];
    [self setupCardNumberField];
    [self setupCardExpiryField];
    [self setupCardCVCField];

    [self.innerView addSubview:self.cardNumberField];
    UIView *opaqueFillView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 34)];
    opaqueFillView.backgroundColor = [UIColor clearColor];
    [self.innerView addSubview:opaqueFillView];
    
    [self addSubview:self.innerView];
    [self addSubview:self.placeholderView];
    [self addSubview:self.scanButton];

    [self stateCardNumber];
}


- (void)setupPlaceholderView
{
    self.placeholderView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 13, 32, 20)];
    self.placeholderView.backgroundColor = [UIColor clearColor];
    self.placeholderView.image = [UIImage imageNamed:@"placeholder"];

    CALayer *clip = [CALayer layer];
    clip.frame = CGRectMake(32, 0, 4, 20);
    clip.backgroundColor = [UIColor clearColor].CGColor;
    [self.placeholderView.layer addSublayer:clip];
}

- (void)setupScanButton
{
    self.scanButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.scanButton.frame = CGRectMake(247, 3, 40, 40);
    [self.scanButton setImage:[UIImage imageNamed:@"scanner"] forState:UIControlStateNormal];
    self.scanButton.tintColor = self.highlightTintColor;
    [self.scanButton addTarget:self action:@selector(scanButtonShowViewController:)
              forControlEvents:UIControlEventTouchUpInside];
}

- (void)scanButtonShowViewController:(id)sender
{
    CardIOPaymentViewController *scanViewController = [[CardIOPaymentViewController alloc]
                                                       initWithPaymentDelegate:self];

    scanViewController.navigationBarTintColor = self.highlightTintColor;
    scanViewController.guideColor = self.highlightTintColor;
    scanViewController.disableManualEntryButtons = YES;
    scanViewController.collectCVV = NO;
    [self.scanDelegate paymentView:self needsScanViewControllerPresented:scanViewController];
}

- (void)userDidCancelPaymentViewController:(CardIOPaymentViewController *)scanViewController
{
    [self.scanDelegate paymentView:self dismissScanViewController:scanViewController];
    [self becomeFirstResponder];
}

- (void)userDidProvideCreditCardInfo:(CardIOCreditCardInfo *)cardInfo
             inPaymentViewController:(CardIOPaymentViewController *)scanViewController
{
    PKCard *initCard = [[PKCard alloc] init];

    initCard.number = cardInfo.cardNumber;
    initCard.expMonth = cardInfo.expiryMonth;
    initCard.expYear = cardInfo.expiryYear % 100;
    self.card = initCard;
    [self.scanDelegate paymentView:self dismissScanViewController:scanViewController];
    [self becomeFirstResponder];
}

- (void)setupCardNumberField
{
    self.cardNumberField = [[PKTextField alloc] initWithFrame:CGRectMake(12, 0, 170, 20)];
    self.cardNumberField.delegate = self;
    self.cardNumberField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:[self.class localizedStringWithKey:@"placeholder.card_number" defaultValue:@"1234 5678 9012 3456"] attributes:@{NSForegroundColorAttributeName:self.placeholderColor}];



    self.cardNumberField.keyboardType = UIKeyboardTypeNumberPad;
    self.cardNumberField.textColor = self.fontColor;
    self.cardNumberField.tintColor = self.fontColor;
    self.cardNumberField.font = self.viewFont;

    [self.cardNumberField.layer setMasksToBounds:YES];
}

- (void)setupCardExpiryField
{
    self.cardExpiryField = [[PKTextField alloc] initWithFrame:CGRectMake(kPKViewCardExpiryFieldStartX, 0, 60, 20)];
    self.cardExpiryField.delegate = self;
    self.cardExpiryField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:[self.class localizedStringWithKey:@"placeholder.card_expiry" defaultValue:@"MM/YY"] attributes:@{NSForegroundColorAttributeName:self.placeholderColor}];
    self.cardExpiryField.keyboardType = UIKeyboardTypeNumberPad;
    self.cardExpiryField.textColor = self.fontColor;
    self.cardExpiryField.tintColor = self.fontColor;
    self.cardExpiryField.font = self.viewFont;

    [self.cardExpiryField.layer setMasksToBounds:YES];
}

- (void)setupCardCVCField
{
    self.cardCVCField = [[PKTextField alloc] initWithFrame:CGRectMake(kPKViewCardCVCFieldStartX, 0, 55, 20)];
    self.cardCVCField.delegate = self;
    self.cardCVCField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:[self.class localizedStringWithKey:@"placeholder.card_cvc" defaultValue:@"CVC"] attributes:@{NSForegroundColorAttributeName:self.placeholderColor}];

    self.cardCVCField.keyboardType = UIKeyboardTypeNumberPad;
    self.cardCVCField.textColor = self.fontColor;
    self.cardCVCField.tintColor = self.fontColor;
    self.cardCVCField.font = self.viewFont;

    [self.cardCVCField.layer setMasksToBounds:YES];
}

// Checks both the old and new localization table (we switched in 3/14 to PaymentKit.strings).
// Leave this in for a long while to preserve compatibility.
+ (NSString *)localizedStringWithKey:(NSString *)key defaultValue:(NSString *)defaultValue
{
    NSString *value = NSLocalizedStringFromTable(key, kPKLocalizedStringsTableName, nil);
    if (value && ![value isEqualToString:key]) { // key == no value
        return value;
    } else {
        value = NSLocalizedStringFromTable(key, kPKOldLocalizedStringsTableName, nil);
        if (value && ![value isEqualToString:key]) {
            return value;
        }
    }

    return defaultValue;
}

#pragma mark - Accessors

- (PKCardNumber *)cardNumber
{
    return [PKCardNumber cardNumberWithString:self.cardNumberField.text];
}

- (PKCardExpiry *)cardExpiry
{
    return [PKCardExpiry cardExpiryWithString:self.cardExpiryField.text];
}

- (PKCardCVC *)cardCVC
{
    return [PKCardCVC cardCVCWithString:self.cardCVCField.text];
}

#pragma mark - State

- (void)stateCardNumber
{
    if (!_isInitialState) {
        // Animate left
        _isInitialState = YES;

        [UIView animateWithDuration:0.05 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.opaqueOverGradientView.alpha = 0.0;
                         } completion:^(BOOL finished) {
        }];
        [UIView animateWithDuration:0.400
                              delay:0
                            options:(UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction)
                         animations:^{
                             self.cardExpiryField.frame = CGRectMake(kPKViewCardExpiryFieldStartX,
                                     self.cardExpiryField.frame.origin.y,
                                     self.cardExpiryField.frame.size.width,
                                     self.cardExpiryField.frame.size.height);
                             self.cardCVCField.frame = CGRectMake(kPKViewCardCVCFieldStartX,
                                     self.cardCVCField.frame.origin.y,
                                     self.cardCVCField.frame.size.width,
                                     self.cardCVCField.frame.size.height);
                             self.cardNumberField.frame = CGRectMake(12,
                                     self.cardNumberField.frame.origin.y,
                                     self.cardNumberField.frame.size.width,
                                     self.cardNumberField.frame.size.height);
                         }
                         completion:^(BOOL completed) {
                             [self.cardExpiryField removeFromSuperview];
                             [self.cardCVCField removeFromSuperview];
                         }];
    }
}

- (void)stateMeta
{
    _isInitialState = NO;

    CGSize cardNumberSize;
    CGSize lastGroupSize;

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
    if ([self.cardNumber.formattedString respondsToSelector:@selector(sizeWithAttributes:)]) {
        NSDictionary *attributes = @{NSFontAttributeName: self.viewFont};

        cardNumberSize = [self.cardNumber.formattedString sizeWithAttributes:attributes];
        lastGroupSize = [self.cardNumber.lastGroup sizeWithAttributes:attributes];
    } else {
        cardNumberSize = [self.cardNumber.formattedString sizeWithFont:self.viewFont];
        lastGroupSize = [self.cardNumber.lastGroup sizeWithFont:self.viewFont];
    }
#else
    NSDictionary *attributes = @{NSFontAttributeName: self.viewFont};

    cardNumberSize = [self.cardNumber.formattedString sizeWithAttributes:attributes];
    lastGroupSize = [self.cardNumber.lastGroup sizeWithAttributes:attributes];
#endif

    CGFloat frameX = self.cardNumberField.frame.origin.x - (cardNumberSize.width - lastGroupSize.width);

    [UIView animateWithDuration:0.05 delay:0.35 options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.opaqueOverGradientView.alpha = 1.0;
                     } completion:^(BOOL finished) {
    }];
    [UIView animateWithDuration:0.400 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.cardExpiryField.frame = CGRectMake(kPKViewCardExpiryFieldEndX,
                self.cardExpiryField.frame.origin.y,
                self.cardExpiryField.frame.size.width,
                self.cardExpiryField.frame.size.height);
        self.cardCVCField.frame = CGRectMake(kPKViewCardCVCFieldEndX,
                self.cardCVCField.frame.origin.y,
                self.cardCVCField.frame.size.width,
                self.cardCVCField.frame.size.height);
        self.cardNumberField.frame = CGRectMake(frameX,
                self.cardNumberField.frame.origin.y,
                self.cardNumberField.frame.size.width,
                self.cardNumberField.frame.size.height);
    }                completion:nil];

    [self addSubview:self.placeholderView];
    [self.innerView addSubview:self.cardExpiryField];
    [self.innerView addSubview:self.cardCVCField];
}

- (void)stateCardCVC
{
    [self.cardCVCField becomeFirstResponder];
}

- (BOOL)isValid
{
    return [self.cardNumber isValid] && [self.cardExpiry isValid] &&
            [self.cardCVC isValidWithType:self.cardNumber.cardType];
}

- (PKCard *)card
{
    PKCard *card = [[PKCard alloc] init];
    card.number = [self.cardNumber string];
    card.cvc = [self.cardCVC string];
    card.expMonth = [self.cardExpiry month];
    card.expYear = [self.cardExpiry year];

    return card;
}

- (void)setCard:(PKCard *)card
{
    PKCardNumber *number = [PKCardNumber cardNumberWithString:card.number];
    
    if (![number isValid]){
        return;
    }
    
    self.cardNumberField.text = [number formattedString];
    [self stateMeta];
    
    if (card.cvc){
        PKCardCVC *cvc = [PKCardCVC cardCVCWithString:card.cvc];
        
        if ([cvc isValid]){
            self.cardCVCField.text = card.cvc;
        }
    }
    
    PKCardExpiry *expiry = [[PKCardExpiry alloc]initWithExpMonth:card.expMonth expYear:card.expYear];
    
    if ([expiry isValid]){
        self.cardExpiryField.text = expiry.formattedString;
    }
    
    [self checkValid];
}

- (void)setScanButtonHidden:(BOOL)hidden
{
    [UIView animateWithDuration:kPKViewPlaceholderViewAnimationDuration delay:0
                        options:UIViewAnimationOptionCurveEaseInOut animations:^{
                            if (hidden) {
                                self.scanButton.layer.opacity = 0.0;
                                self.scanButton.layer.transform = CATransform3DMakeScale(0.8, 0.8, 0.8);
                            }
                            else {
                                self.scanButton.hidden = NO;
                                self.scanButton.layer.opacity = 1;
                                self.scanButton.layer.transform = CATransform3DIdentity;
                            }
                        } completion:^(BOOL finished) {
                            self.scanButton.hidden = hidden;
                        }];
}

- (void)setPlaceholderViewImage:(UIImage *)image
{
    if (![self.placeholderView.image isEqual:image]) {
        __block __unsafe_unretained UIView *previousPlaceholderView = self.placeholderView;
        [UIView animateWithDuration:kPKViewPlaceholderViewAnimationDuration delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.placeholderView.layer.opacity = 0.0;
                             self.placeholderView.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1.2);
                         } completion:^(BOOL finished) {
            [previousPlaceholderView removeFromSuperview];
        }];
        self.placeholderView = nil;

        [self setupPlaceholderView];
        self.placeholderView.image = image;
        self.placeholderView.layer.opacity = 0.0;
        self.placeholderView.layer.transform = CATransform3DMakeScale(0.8, 0.8, 0.8);
        [self insertSubview:self.placeholderView belowSubview:previousPlaceholderView];
        [UIView animateWithDuration:kPKViewPlaceholderViewAnimationDuration delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.placeholderView.layer.opacity = 1.0;
                             self.placeholderView.layer.transform = CATransform3DIdentity;
                         } completion:^(BOOL finished) {
        }];
    }
}

- (void)setPlaceholderToCVC
{
    PKCardNumber *cardNumber = [PKCardNumber cardNumberWithString:self.cardNumberField.text];
    PKCardType cardType = [cardNumber cardType];

    if (cardType == PKCardTypeAmex) {
        [self setPlaceholderViewImage:[UIImage imageNamed:@"cvc-amex"]];
    } else {
        [self setPlaceholderViewImage:[UIImage imageNamed:@"cvc"]];
    }
    [self setScanButtonHidden:YES];
}

- (void)setPlaceholderToCardType
{
    PKCardNumber *cardNumber = [PKCardNumber cardNumberWithString:self.cardNumberField.text];
    PKCardType cardType = [cardNumber cardType];
    NSString *cardTypeName = @"placeholder";

    switch (cardType) {
        case PKCardTypeAmex:
            cardTypeName = @"amex";
            break;
        case PKCardTypeDinersClub:
            cardTypeName = @"diners";
            break;
        case PKCardTypeDiscover:
            cardTypeName = @"discover";
            break;
        case PKCardTypeJCB:
            cardTypeName = @"jcb";
            break;
        case PKCardTypeMasterCard:
            cardTypeName = @"mastercard";
            break;
        case PKCardTypeVisa:
            cardTypeName = @"visa";
            break;
        default:
            break;
    }

    [self setPlaceholderViewImage:[UIImage imageNamed:cardTypeName]];
    [self setScanButtonHidden:cardType != PKCardTypeUnknown];
}

#pragma mark - Delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (_isInitialState) {
        self.validView.backgroundColor = self.validColor;
        textField.tintColor = self.validColor;
    }
    if ([textField isEqual:self.cardCVCField]) {
        [self setPlaceholderToCVC];
    } else {
        [self setPlaceholderToCardType];
    }

    if ([textField isEqual:self.cardNumberField] && !_isInitialState) {
        [self stateCardNumber];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    if ([textField isEqual:self.cardNumberField]) {
        return [self cardNumberFieldShouldChangeCharactersInRange:range replacementString:replacementString];
    }

    if ([textField isEqual:self.cardExpiryField]) {
        return [self cardExpiryShouldChangeCharactersInRange:range replacementString:replacementString];
    }

    if ([textField isEqual:self.cardCVCField]) {
        return [self cardCVCShouldChangeCharactersInRange:range replacementString:replacementString];
    }

    return YES;
}

- (void)pkTextFieldDidBackSpaceWhileTextIsEmpty:(PKTextField *)textField
{
    if (textField == self.cardCVCField)
        [self.cardExpiryField becomeFirstResponder];
    else if (textField == self.cardExpiryField)
    {
        [self stateCardNumber];
        [self.cardNumberField becomeFirstResponder];
    }
    
}

- (BOOL)cardNumberFieldShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [self.cardNumberField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PKTextField textByRemovingUselessSpacesFromString:resultString];
    PKCardNumber *cardNumber = [PKCardNumber cardNumberWithString:resultString];

    if (![cardNumber isPartiallyValid])
        return NO;

    if (replacementString.length > 0) {
        self.cardNumberField.text = [cardNumber formattedStringWithTrail];
    } else {
        self.cardNumberField.text = [cardNumber formattedString];
    }

    [self setPlaceholderToCardType];

    if ([cardNumber isValid]) {
        [self textFieldIsValid:self.cardNumberField];
        [self stateMeta];
        [self.cardExpiryField becomeFirstResponder];

    } else if ([cardNumber isValidLength] && ![cardNumber isValidLuhn]) {
        [self textFieldIsInvalid:self.cardNumberField withErrors:YES];

    } else if (![cardNumber isValidLength]) {
        [self textFieldIsInvalid:self.cardNumberField withErrors:NO];
    }

    return NO;
}

- (BOOL)cardExpiryShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [self.cardExpiryField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PKTextField textByRemovingUselessSpacesFromString:resultString];
    PKCardExpiry *cardExpiry = [PKCardExpiry cardExpiryWithString:resultString];

    if (![cardExpiry isPartiallyValid]) return NO;

    // Only support shorthand year
    if ([cardExpiry formattedString].length > 5) return NO;

    if (replacementString.length > 0) {
        self.cardExpiryField.text = [cardExpiry formattedStringWithTrail];
    } else {
        self.cardExpiryField.text = [cardExpiry formattedString];
    }

    if ([cardExpiry isValid]) {
        [self textFieldIsValid:self.cardExpiryField];
        [self stateCardCVC];

    } else if ([cardExpiry isValidLength] && ![cardExpiry isValidDate]) {
        [self textFieldIsInvalid:self.cardExpiryField withErrors:YES];
    } else if (![cardExpiry isValidLength]) {
        [self textFieldIsInvalid:self.cardExpiryField withErrors:NO];
    }

    return NO;
}

- (BOOL)cardCVCShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [self.cardCVCField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PKTextField textByRemovingUselessSpacesFromString:resultString];
    PKCardCVC *cardCVC = [PKCardCVC cardCVCWithString:resultString];
    PKCardType cardType = [[PKCardNumber cardNumberWithString:self.cardNumberField.text] cardType];

    // Restrict length
    if (![cardCVC isPartiallyValidWithType:cardType]) return NO;

    // Strip non-digits
    self.cardCVCField.text = [cardCVC string];

    if ([cardCVC isValidWithType:cardType]) {
        [self textFieldIsValid:self.cardCVCField];
    } else {
        [self textFieldIsInvalid:self.cardCVCField withErrors:NO];
    }

    return NO;
}


#pragma mark - Validations

- (void)checkValid
{
    if ([self isValid]) {
        _isValidState = YES;
        self.validView.backgroundColor = self.validColor;
        self.cardNumberField.textColor = self.validColor;
        self.cardExpiryField.textColor = self.validColor;
        self.cardCVCField.textColor = self.validColor;

        self.cardNumberField.tintColor = self.validColor;
        self.cardExpiryField.tintColor = self.validColor;
        self.cardCVCField.tintColor = self.validColor;

        if ([self.delegate respondsToSelector:@selector(paymentView:withCard:isValid:)]) {
            [self.delegate paymentView:self withCard:self.card isValid:YES];
        }

    } else {
        if (_isValidState) {
            _isValidState = NO;
            self.validView.backgroundColor = self.invalidColor;
            self.cardNumberField.textColor = self.invalidColor;
            self.cardExpiryField.textColor = self.invalidColor;
            self.cardCVCField.textColor = self.invalidColor;
            self.cardNumberField.tintColor = self.invalidColor;
            self.cardExpiryField.tintColor = self.invalidColor;
            self.cardCVCField.tintColor = self.invalidColor;
            if ([self.delegate respondsToSelector:@selector(paymentView:withCard:isValid:)]) {
                [self.delegate paymentView:self withCard:self.card isValid:NO];
            }
        }
    }
}

- (void)textFieldIsValid:(UITextField *)textField
{
    textField.textColor = self.validColor;
    [self checkValid];
}

- (void)textFieldIsInvalid:(UITextField *)textField withErrors:(BOOL)errors
{
    if (errors) {
        if ([textField isFirstResponder]) {
            textField.textColor = self.invalidColor;
            textField.tintColor = self.invalidColor;
            self.validView.backgroundColor = self.invalidColor;
        }
    } else {
        textField.textColor = self.fontColor;
        textField.tintColor = self.fontColor;
        self.validView.backgroundColor = self.validColor;
    }
    [self checkValid];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (self.firstResponderField == nil) {
        if (self.validView.backgroundColor != self.invalidColor) {
            self.validView.backgroundColor = self.noFocusColor;
        }
    }
}

#pragma mark -
#pragma mark UIResponder
- (UIResponder *)firstResponderField;
{
    NSArray *responders = @[self.cardNumberField, self.cardExpiryField, self.cardCVCField];
    for (UIResponder *responder in responders) {
        if (responder.isFirstResponder) {
            return responder;
        }
    }

    return nil;
}

- (PKTextField *)firstInvalidField;
{
    if (![[PKCardNumber cardNumberWithString:self.cardNumberField.text] isValid])
        return self.cardNumberField;
    else if (![[PKCardExpiry cardExpiryWithString:self.cardExpiryField.text] isValid])
        return self.cardExpiryField;
    else if (![[PKCardCVC cardCVCWithString:self.cardCVCField.text] isValid])
        return self.cardCVCField;

    return nil;
}

- (PKTextField *)nextFirstResponder;
{
    if (self.firstInvalidField)
        return self.firstInvalidField;

    return self.cardCVCField;
}

- (BOOL)isFirstResponder;
{
    return self.firstResponderField.isFirstResponder;
}

- (BOOL)canBecomeFirstResponder;
{
    return self.nextFirstResponder.canBecomeFirstResponder;
}

- (BOOL)becomeFirstResponder;
{
    return [self.nextFirstResponder becomeFirstResponder];
}

- (BOOL)canResignFirstResponder;
{
    return self.firstResponderField.canResignFirstResponder;
}

- (BOOL)resignFirstResponder;
{
    return [self.firstResponderField resignFirstResponder];
}

#pragma mark - Accessors

- (void)setHighlightTintColor:(UIColor *)highlightTintColor
{
    _highlightTintColor = highlightTintColor;
    self.scanButton.tintColor = highlightTintColor;
}

- (void)setViewFont:(UIFont *)viewFont {
    _viewFont = viewFont;
    self.cardNumberField.font = self.viewFont;
    self.cardExpiryField.font = self.viewFont;
    self.cardCVCField.font = self.viewFont;
}

@end
