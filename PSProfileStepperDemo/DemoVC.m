//
//  ViewController.m
//  PSProfileStepperDemo
//
//  Created by Pramod Kumar Pranav on 5/27/16.
//  Copyright © 2016 Pramod. All rights reserved.
//

#import "DemoVC.h"
#import "PSProfileStepper.h"

@interface DemoVC ()
{
    int index;
}
@property (nonatomic, strong) IBOutlet PSProfileStepper *stepperView;
@property (nonatomic, strong) IBOutlet UILabel *progressLabelIndex;

- (IBAction)changeSliderValue:(id)sender;
- (IBAction)changeByPrevIndex:(id)sender;
- (IBAction)changeByNextIndex:(id)sender;

@end

@implementation DemoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    index = 0;
    // Do any additional setup after loading the view, typically from a nib.
    [self.progressLabelIndex setText:[NSString stringWithFormat:@"%lu", (unsigned long)self.stepperView.index]];
    [self.stepperView setIndex:2 animated:YES];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)changeSliderValue:(PSProfileStepper*)sender {
    [self.progressLabelIndex setText:[NSString stringWithFormat:@"%lu", (unsigned long)sender.index]];
}

- (IBAction)changeByPrevIndex:(id)sender
{
    if (index >= 6 )
    {
        index = index - 6;
    }
    
    
    [self.stepperView setIndex:index animated:YES];
    [self.progressLabelIndex setText:[NSString stringWithFormat:@"%lu", (unsigned long)self.stepperView.index]];
    
}
- (IBAction)changeByNextIndex:(id)sender
{
    if (index <= self.stepperView.maxCount - 6)
    {
        index = index + 6;
    }
    
    [self.stepperView setIndex:index animated:YES];
    [self.progressLabelIndex setText:[NSString stringWithFormat:@"%lu", (unsigned long)self.stepperView.index]];
}
@end

