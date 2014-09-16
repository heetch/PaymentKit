//
//  PKPaymentField.h
//  PKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CardIO/CardIO.h>
#import "PKCard.h"
#import "PKCardNumber.h"
#import "PKCardExpiry.h"
#import "PKCardCVC.h"
#import "PKAddressZip.h"
#import "PKUSAddressZip.h"

@class PKView, PKTextField;

@protocol PKViewDelegate <NSObject>
@optional
- (void)paymentView:(PKView *)paymentView withCard:(PKCard *)card isValid:(BOOL)valid;
@end

@protocol PKViewScanDelegate <NSObject>
- (void)paymentView:(PKView *)paymentView needsScanViewControllerPresented:(CardIOPaymentViewController*)scanViewController;
- (void)paymentView:(PKView *)paymentView dismissScanViewController:(CardIOPaymentViewController*)scanViewController;
@end

@interface PKView : UIView

- (BOOL)isValid;

@property (nonatomic, copy) NSString *cardIOToken;
@property (nonatomic, strong) UIColor *highlightTintColor;

@property (nonatomic, readonly) UIView *opaqueOverGradientView;
@property (nonatomic, readonly) PKCardNumber *cardNumber;
@property (nonatomic, readonly) PKCardExpiry *cardExpiry;
@property (nonatomic, readonly) PKCardCVC *cardCVC;
@property (nonatomic, readonly) PKAddressZip *addressZip;

@property IBOutlet UIView *innerView;
@property IBOutlet UIView *clipView;
@property IBOutlet PKTextField *cardNumberField;
@property IBOutlet PKTextField *cardExpiryField;
@property IBOutlet PKTextField *cardCVCField;
@property IBOutlet UIImageView *placeholderView;
@property IBOutlet UIButton    *scanButton;
@property (nonatomic, weak) id <PKViewDelegate> delegate;
@property (nonatomic, weak) id <PKViewScanDelegate> scanDelegate;
@property (nonatomic, readwrite) PKCard *card;

@end
