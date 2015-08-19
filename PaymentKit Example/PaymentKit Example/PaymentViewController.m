//
//  ViewController.m
//  PKPayment Example
//
//  Created by Alex MacCaw on 1/21/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "PaymentViewController.h"

@interface PaymentViewController()

@property IBOutlet PKView* paymentView;

@end


#pragma mark -

@implementation PaymentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    self.title = @"Change Card";
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(save:)];
    saveButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = saveButton;
    
    self.paymentView = [[PKView alloc] init];
    //[[PKView alloc] initWithFont:[UIFont systemFontOfSize:9] fontColor:[UIColor redColor] noFocusColor:[UIColor greenColor] invalidColor:[UIColor yellowColor] validColor:[UIColor redColor] placeholderColor:[UIColor blueColor]];
    self.paymentView.frame = CGRectMake(15, 25, 290, 45);
    self.paymentView.highlightTintColor = [UIColor grayColor];
    self.paymentView.cardIOToken = @"be537e6fc1e843ee83ce0ba8b56fad94";
    self.paymentView.delegate = self;
    
    [self.view addSubview:self.paymentView];
}


- (void) paymentView:(PKView *)paymentView withCard:(PKCard *)card isValid:(BOOL)valid
{
    self.navigationItem.rightBarButtonItem.enabled = valid;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)save:(id)sender
{
    PKCard* card = self.paymentView.card;
    
    NSLog(@"Card last4: %@", card.last4);
    NSLog(@"Card expiry: %lu/%lu", (unsigned long)card.expMonth, (unsigned long)card.expYear);
    NSLog(@"Card cvc: %@", card.cvc);
    
    [[NSUserDefaults standardUserDefaults] setValue:card.last4 forKey:@"card.last4"];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)paymentView:(PKView *)paymentView needsScanViewControllerPresented:(CardIOPaymentViewController *)scanViewController
{
    [self presentViewController:scanViewController animated:YES completion:nil];
}

- (void)paymentView:(PKView *)paymentView dismissScanViewController:(CardIOPaymentViewController*)scanViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
