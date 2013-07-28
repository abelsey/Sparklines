/* 
 Copyright © 2011-2013 A. Belsey. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SparklinesViewController.h"
#import "ASBSparkLineView.h"

@interface SparklinesViewController() {
    NSMutableArray *m_glucoseData;
    NSMutableArray *m_temperatureData;
    NSMutableArray *m_heartRateData;
}

- (void)setup;

@end


@implementation SparklinesViewController

@synthesize sparkLineView1, sparkLineView2, sparkLineView3;
@synthesize sparkLineView4, sparkLineView5, sparkLineView6;
@synthesize allSparklines;


// configure test range overlay limits (note, I'm not medically qualified in any way, these are made up...)
const float glucoseMinLimit = 5.0f;
const float glucoseMaxLimit = 6.8f;
const float tempMinLimit = 36.9f;
const float tempMaxLimit = 37.4f;
const float heartRateMinLimit = 45;
const float heartRateMaxLimit = 85;


#pragma mark - Object Lifecycle

// designated initializer
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)init {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [self setup];
}

// loads the data sets from the files in the main bundle
- (void)setup {

    m_glucoseData = [[NSMutableArray alloc] init];
    m_temperatureData = [[NSMutableArray alloc] init];
    m_heartRateData = [[NSMutableArray alloc] init];

    NSArray *dataArray = [NSArray arrayWithObjects:m_glucoseData, m_temperatureData, m_heartRateData, nil];
    NSArray *fileNames = [NSArray arrayWithObjects:@"glucose_data.txt", @"temperature_data.txt", @"heartRate_data.txt", nil];
    
    [fileNames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        // read in the dummy data and allocate to the appropriate view
        NSError *err;
        NSString *dataFile = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:obj];
        NSString *contents = [[NSString alloc] initWithContentsOfFile:dataFile encoding:NSUTF8StringEncoding error:&err];
        
        if (contents) {
            
            NSScanner *scanner = [[NSScanner alloc] initWithString:contents];
            
            NSMutableArray *data = [dataArray objectAtIndex:idx];
            while ([scanner isAtEnd] == NO) {
                float scannedValue = 0;
                if ([scanner scanFloat:&scannedValue]) {
                    NSNumber *num = [[NSNumber alloc] initWithFloat:scannedValue];
                    [data addObject:num];
                }
            }
            
        } else {
            NSLog(@"failed to read in data file %@: %@", [fileNames objectAtIndex:idx], [err localizedDescription]);
        }
        
    }];

}



#pragma mark - View lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // we have two test views to load
    
    UIColor *darkRed = [UIColor colorWithRed:0.6f green:0.0f blue:0.0f alpha:1.0f];
    UIColor *darkGreen = [UIColor colorWithRed:0.0f green:0.6f blue:0.0f alpha:1.0f];
    
    // small ones are 1 - 3
    self.sparkLineView1.dataValues = m_glucoseData;
    self.sparkLineView1.labelText = @"Glucose";
    self.sparkLineView1.currentValueColor = darkRed;
    
    self.sparkLineView2.dataValues = m_temperatureData;
    self.sparkLineView2.labelText = @"Temp";
    self.sparkLineView2.currentValueColor = darkGreen;
    self.sparkLineView2.penColor = [UIColor blueColor];
    self.sparkLineView2.penWidth = 2.0f;

    self.sparkLineView3.dataValues = m_heartRateData;
    self.sparkLineView3.labelText = @"Pulse";
    self.sparkLineView3.currentValueColor = darkGreen;
    self.sparkLineView3.currentValueFormat = @"%.0f";
    self.sparkLineView3.penColor = [UIColor redColor];
    self.sparkLineView3.penWidth = 3.0f;

    // large ones are 4 - 6
    self.sparkLineView4.dataValues = m_glucoseData;
    self.sparkLineView4.labelText = @"Glucose";
    self.sparkLineView4.currentValueColor = darkRed;
    
    self.sparkLineView5.dataValues = m_temperatureData;
    self.sparkLineView5.labelText = @"Temp";
    self.sparkLineView5.currentValueColor = darkGreen;
    self.sparkLineView5.penColor = [UIColor blueColor];
    self.sparkLineView5.penWidth = 3.0f;
    
    self.sparkLineView6.dataValues = m_heartRateData;
    self.sparkLineView6.labelText = @"Pulse";
    self.sparkLineView6.currentValueColor = darkGreen;
    self.sparkLineView6.currentValueFormat = @"%.0f";
    self.sparkLineView6.penColor = [UIColor redColor];
    self.sparkLineView6.penWidth = 6.0f;
    
    self.allSparklines = [NSArray arrayWithObjects:self.sparkLineView1, self.sparkLineView2, self.sparkLineView3,
                          self.sparkLineView4, self.sparkLineView5, self.sparkLineView6, nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    } else {
        return YES;
    }
}

// called when the "Show/Hide Range Overlays" button is touched
- (IBAction)toggleShowOverlays:(id)sender {
    
    for (ASBSparkLineView *obj in self.allSparklines)
        obj.showRangeOverlay = !obj.showRangeOverlay;
    
    NSString *buttonText = [NSString stringWithFormat:@"%@ Range Overlays",
                            (self.sparkLineView1.showRangeOverlay) ? @"Hide" : @"Show"];
    [((UIButton *)sender) setTitle:buttonText forState:UIControlStateNormal];
    
    // if the overlays are enabled, we define the limits, otherwise we reset them (the view will auto-scale)
    if (self.sparkLineView1.showRangeOverlay) {
        
        self.sparkLineView1.rangeOverlayLowerLimit = [NSNumber numberWithFloat:glucoseMinLimit];
        self.sparkLineView1.rangeOverlayUpperLimit = [NSNumber numberWithFloat:glucoseMaxLimit];
        self.sparkLineView2.rangeOverlayLowerLimit = [NSNumber numberWithFloat:tempMinLimit];
        self.sparkLineView2.rangeOverlayUpperLimit = [NSNumber numberWithFloat:tempMaxLimit];
        self.sparkLineView3.rangeOverlayLowerLimit = [NSNumber numberWithFloat:heartRateMinLimit];
        self.sparkLineView3.rangeOverlayUpperLimit = [NSNumber numberWithFloat:heartRateMaxLimit];
        self.sparkLineView4.rangeOverlayLowerLimit = [NSNumber numberWithFloat:glucoseMinLimit];
        self.sparkLineView4.rangeOverlayUpperLimit = [NSNumber numberWithFloat:glucoseMaxLimit];
        self.sparkLineView5.rangeOverlayLowerLimit = [NSNumber numberWithFloat:tempMinLimit];
        self.sparkLineView5.rangeOverlayUpperLimit = [NSNumber numberWithFloat:tempMaxLimit];
        self.sparkLineView6.rangeOverlayLowerLimit = [NSNumber numberWithFloat:heartRateMinLimit];
        self.sparkLineView6.rangeOverlayUpperLimit = [NSNumber numberWithFloat:heartRateMaxLimit];
        
    } else {
        // make them all nil, which will result in an auto-scale of the data values
        for (ASBSparkLineView *obj in self.allSparklines) {
            obj.rangeOverlayLowerLimit = nil;
            obj.rangeOverlayUpperLimit = nil;
        }
    }
}

// called when the "Show/Hide Range Current Values" button is touched
-(IBAction)toggleCurrentValues:(id)sender {
    
    for (ASBSparkLineView *obj in self.allSparklines)
        obj.showCurrentValue = !obj.showCurrentValue;
    
    NSString *buttonText = [NSString stringWithFormat:@"%@ Current Values",
                            (self.sparkLineView1.showCurrentValue) ? @"Hide" : @"Show"];
    [((UIButton *)sender) setTitle:buttonText forState:UIControlStateNormal];
}

@end
