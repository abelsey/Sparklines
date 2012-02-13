/* 
 Copyright © 2011 A. Belsey. All Rights Reserved.
 
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


// You can change the constants defined within this file to change the layout and
// appearance of the Sparkline view.

#import "ASBSparkLineView.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark Class Constants

#define LABEL_FONT @"Helvetica"
static const CGFloat  MAX_TEXT_FRAC         = 0.5f;     // maximum fraction of view to give to the textual part
static const CGFloat  DEFAULT_FONT_SIZE     = 12.0f;    // we'll try to use this font size
static const CGFloat  MIN_FONT_SIZE         = 10.0f;    // this is the minimum font size, after that, we'll truncate

static const CGFloat  MARKER_MIN_SIZE       = 4.0f;     // maximum size of the anchor marker we'll use (in points)
static const CGFloat  DEF_MARKER_SIZE_FRAC  = 0.2f;     // default fraction of the view height we'll use for the anchor marker
static const CGFloat  MARKER_MAX_SIZE       = 8.0f;     // maximum size of the anchor marker we'll use (in points)

static const CGFloat  GRAPH_X_BORDER        = 2.0f;     // horizontal border width for the graph line (in points)
static const CGFloat  GRAPH_Y_BORDER        = 2.0f;     // vertical border width for the graph line (in points)

static const CGFloat  CONSTANT_GRAPH_BUFFER = 0.1f;     // fraction to move the graph limits when min = max

#define DEFAULT_LABEL_COL        darkGrayColor          // default label text colour
#define DEFAULT_CURRENTVALUE_COL blueColor              // default current value colour (including the anchor marker)
#define DEFAULT_OVERLAY_COL      colorWithRed:0.8f green:0.8f blue:0.8f alpha:1.0   // default overlay colour (light gray)
#define PEN_COL                  blackColor             // default graph line colour (black)
#define DEFAULT_GRAPH_PEN_WIDTH  1.0f

static const CGFloat  GRAPH_PEN_WIDTH       = DEFAULT_GRAPH_PEN_WIDTH;     // pen width for the graph line (in *pixels*)

// no user-tweakable bits beyond this point...


#pragma mark Private Interface

static inline float yPlotValue(float maxHeight, float yInc, float val, float minVal, float penWidth);

// private interface section
@interface ASBSparkLineView()

// redefine these as writable
@property (nonatomic, copy) NSNumber *dataMinimum;
@property (nonatomic, copy) NSNumber *dataMaximum;

// private methods
- (void)setup;
- (void)createDataStatistics;

@end


#pragma mark Implementation Section

@implementation ASBSparkLineView

// a number of set accessors are also specifically defined below so that we can request a re-draw
@synthesize dataValues=m_dataValues;
@synthesize labelText=m_labelText, labelColor=m_labelColour;
@synthesize showCurrentValue=m_showCurrentValue, currentValueColor=m_currentValueColour, currentValueFormat=m_currentValueFormat;
@synthesize showRangeOverlay=m_showRangeOverlay, rangeOverlayColor=m_rangeOverlayColour;
@synthesize rangeOverlayLowerLimit=m_rangeOverlayLowerLimit, rangeOverlayUpperLimit=m_rangeOverlayUpperLimit;
@synthesize dataMinimum=m_dataMinimum, dataMaximum=m_dataMaximum;
@synthesize penColor=m_penColor, penWidth=m_penWidth;


#pragma mark Property Accessors

// the current value is actually the last element of the data array
- (NSNumber *)dataCurrentValue {
    return [m_dataValues lastObject];
}

// all the set accessors below are needed to cause a re-display on change
- (void)setDataValues:(NSArray *)dataValues {
    if (![m_dataValues isEqualToArray:dataValues]) {
        
        m_dataValues = dataValues;
        [self createDataStatistics];
        [self setNeedsDisplay];
    }
}

- (void)setLabelText:(NSString *)labelText {
    if (![m_labelText isEqualToString:labelText]) {
       
        m_labelText = [labelText copy];
        [self setNeedsDisplay];
    }
}

- (void)setLabelColor:(UIColor *)labelColor {
    if (![m_labelColour isEqual:labelColor]) {
       
        m_labelColour = labelColor;
        [self setNeedsDisplay];
    }
}

- (void)setShowCurrentValue:(BOOL)showCurrentValue {
    if (m_showCurrentValue != showCurrentValue) {
        m_showCurrentValue = showCurrentValue;
        [self setNeedsDisplay];
    }
}

-(void)setCurrentValueColor:(UIColor *)currentValueColor {
    if (![m_currentValueColour isEqual:currentValueColor]) {
       
        m_currentValueColour = currentValueColor;
        [self setNeedsDisplay];
    }
}

-(void)setCurrentValueFormat:(NSString *)currentValueFormat {
    if (![m_currentValueFormat isEqualToString:currentValueFormat]) {
        
        m_currentValueFormat = [currentValueFormat copy];
        [self setNeedsDisplay];
    }
}

- (void)setShowRangeOverlay:(BOOL)showRangeOverlay {
    if (m_showRangeOverlay != showRangeOverlay) {
        m_showRangeOverlay = showRangeOverlay;
        [self setNeedsDisplay];
    }
}

-(void)setRangeOverlayColor:(UIColor *)rangeOverlayColor {
    if (![m_rangeOverlayColour isEqual:rangeOverlayColor]) {
        
        m_rangeOverlayColour = rangeOverlayColor;
        [self setNeedsDisplay];
    }
}

-(void)setRangeOverlayLowerLimit:(NSNumber *)rangeOverlayLowerLimit {
    if (rangeOverlayLowerLimit && ![m_rangeOverlayLowerLimit isEqualToNumber:rangeOverlayLowerLimit]) {
       
        m_rangeOverlayLowerLimit = [rangeOverlayLowerLimit copy];
    }
    [self setNeedsDisplay];
}

-(void)setRangeOverlayUpperLimit:(NSNumber *)rangeOverlayUpperLimit {
    if (rangeOverlayUpperLimit && ![m_rangeOverlayUpperLimit isEqualToNumber:rangeOverlayUpperLimit]) {
        
        m_rangeOverlayUpperLimit = [rangeOverlayUpperLimit copy];
    }
    [self setNeedsDisplay];
}

#pragma mark Lifecycle

// designated initializer
- (id)initWithData:(NSArray *)data frame:(CGRect)frame label:(NSString *)label {

    self = [super initWithFrame:frame];
    if (self) {
        m_dataValues = data;
        m_labelText = label;
        [self createDataStatistics];
        [self setup];
        [self setNeedsDisplay];
    }
    
    return self;    
}

// convienence initializer
- (id)initWithData:(NSArray *)data frame:(CGRect)frame {
    return [self initWithData:data frame:frame label:nil];
}

// convienence initializer
- (id)initWithFrame:(CGRect)frame {
    return [self initWithData:[NSArray array] frame:frame label:nil];
}

// convienence initializer
- (void)awakeFromNib {
    [self setup];
}


// configures the defaults (used in init or when waking from a nib)
- (void)setup {
    
    m_labelColour = [UIColor DEFAULT_LABEL_COL];
    
    m_showCurrentValue = YES;
    m_currentValueColour = [UIColor DEFAULT_CURRENTVALUE_COL];
    m_currentValueFormat = @"%.1f";
    
    m_showRangeOverlay = NO;
    m_rangeOverlayColour = [UIColor DEFAULT_OVERLAY_COL];
    m_rangeOverlayLowerLimit = [self.dataMinimum copy];
    m_rangeOverlayUpperLimit = [self.dataMaximum copy];
    
    // ensure we redraw correctly when resized
    self.contentMode = UIViewContentModeRedraw;
    
    // and we have a nice rounded shape...
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 5.0f;
}

// ingests the data values, and calculates the min and max values (for auto-scaling)
- (void)createDataStatistics {
    
    const NSInteger numData = [self.dataValues count];

    /// special cases first
    if (numData == 0) {

        self.dataMinimum = nil;
        self.dataMaximum = nil;

    } else if (numData == 1) {

        self.dataMinimum = [self.dataValues lastObject];
        self.dataMaximum = [self.dataValues lastObject];

    } else {

        float min = [[m_dataValues objectAtIndex:0] floatValue];
        float max = min;

        // extract the min and max values (ignore any non-NSNumber objects)
        for (id obj in self.dataValues) {
            if ([obj isKindOfClass:[NSNumber class]]) {
                const float val = [obj floatValue];
                if (val < min)
                    min = val;
                else if (val > max)
                    max = val;
            }
        }

        self.dataMinimum = [NSNumber numberWithFloat:min];
        self.dataMaximum = [NSNumber numberWithFloat:max];
    }
}


#pragma mark Drawing Methods

// draws all the elements of this view
- (void)drawRect:(CGRect)rect {

    CGContextRef context = UIGraphicsGetCurrentContext();

    // ---------------------------------------------------
    // Text label Drawing
    // ---------------------------------------------------

    const CGFloat maxTextWidth = CGRectGetWidth(self.bounds) * MAX_TEXT_FRAC;

    // see how much text we have to show
    if ( self.labelText == nil )
        self.labelText = @"not set";
    
    NSMutableString *graphText = [[NSMutableString alloc] initWithString:self.labelText];
    if (self.showCurrentValue) {
        [graphText appendString:@" "];
        [graphText appendFormat:self.currentValueFormat, [self.dataCurrentValue floatValue]];
    }

    // calculate the width the text would take with the specified font
    UIFont *font = [UIFont fontWithName:LABEL_FONT size:DEFAULT_FONT_SIZE];
    CGFloat actualFontSize;
    CGSize textSize = [graphText sizeWithFont:font
                                  minFontSize:MIN_FONT_SIZE
                               actualFontSize:&actualFontSize
                                     forWidth:maxTextWidth
                                lineBreakMode:UILineBreakModeClip];
   
    
    // first we draw the label
    const CGFloat textStartX = (CGRectGetWidth(self.bounds) * 0.975f) - textSize.width;
    const CGFloat textStartY = CGRectGetMidY(self.bounds) - (textSize.height / 2.0f);
    CGPoint textStart = CGPointMake(textStartX, textStartY);

    // using the specified font
    font = [UIFont fontWithName:LABEL_FONT size:actualFontSize];
    CGSize labelDrawnSize = [self.labelText drawAtPoint:textStart withFont:font];
    
    // conditionally draw the current value in the chosen colour
    if (self.showCurrentValue) {
        CGContextSaveGState(context);
        [self.currentValueColor setFill];
        textStart = CGPointMake(textStartX + labelDrawnSize.width, textStartY);
        [[@" " stringByAppendingFormat:self.currentValueFormat, [self.dataCurrentValue floatValue]] drawAtPoint:textStart
                                                                                                       withFont:font];
        CGContextRestoreGState(context);
    }
    

    // ---------------------------------------------------
    // Graph Drawing
    // ---------------------------------------------------

    // calculate the view fraction that will be the graph
    const CGFloat graphSize = (CGRectGetWidth(self.bounds) * 0.95f) - textSize.width;
    const CGFloat graphFrac = graphSize / CGRectGetWidth(self.bounds);
    
    // calculate the graph area and X & Y widths and scales
    const float dataMin = [self.dataMinimum floatValue];
    const float dataMax = [self.dataMaximum floatValue];

    const CGFloat fullWidth = CGRectGetWidth(self.bounds);
    const CGFloat fullHeight = CGRectGetHeight(self.bounds);
    const CGFloat sparkWidth  = (fullWidth  - (2 * GRAPH_X_BORDER)) * graphFrac;
    const CGFloat sparkHeight = fullHeight - (2 * GRAPH_Y_BORDER);

    // defaults: upper and lower graph bounds are data maximum and minimum, respectively
    float graphMax = dataMax;
    float graphMin = dataMin;
    
    // disable overlay if the upper limit is at or below the lower limit
    if (self.showRangeOverlay && (self.rangeOverlayUpperLimit != nil) && (self.rangeOverlayLowerLimit != nil) &&
        ([self.rangeOverlayUpperLimit floatValue] <= [self.rangeOverlayLowerLimit floatValue]))
        self.showRangeOverlay = NO;

    // default: undefined overlay limit means "no limit", so overlay will extend to view border
    CGFloat overlayOrigin = 0;
    CGFloat overlayHeight = fullHeight;
    
    // upper scale limit will be the maximum of (defined) overlay and data maxima
    if (self.rangeOverlayUpperLimit != nil) {
        const float rangeUpper = [self.rangeOverlayUpperLimit floatValue];
        if (rangeUpper > graphMax) {
            graphMax = rangeUpper;
        }
    }
    
    // lower scale limit will be the minimum of (defined) overlay and data minima
    if (self.rangeOverlayLowerLimit != nil) {
        const float rangeLower = [self.rangeOverlayLowerLimit floatValue];
        if (rangeLower < graphMin) {
            graphMin = rangeLower;
        }
    }

    // special case if min = max, push the limits 10% further
    if (graphMin == graphMax) {
        graphMin *= 1.0f - CONSTANT_GRAPH_BUFFER;
        graphMax *= 1.0f + CONSTANT_GRAPH_BUFFER;
    }
    
    // show the graph overlay if (still) enabled
    if (self.showRangeOverlay) {

        // set the graph location of the overlay upper and lower limits, if defined
        if (self.rangeOverlayUpperLimit != nil) {
            overlayOrigin = yPlotValue(fullHeight, sparkHeight / (graphMax - graphMin),
                                       [self.rangeOverlayUpperLimit floatValue], graphMin, self.penWidth);
        }
        if (self.rangeOverlayLowerLimit != nil) {
            float lowerY = yPlotValue(fullHeight, sparkHeight / (graphMax - graphMin),
                                       [self.rangeOverlayLowerLimit floatValue], graphMin, self.penWidth);
            overlayHeight = lowerY - overlayOrigin;
        }

        // draw the overlay
        [self.rangeOverlayColor setFill];
        CGRect overlayRect = CGRectMake(GRAPH_X_BORDER, overlayOrigin, sparkWidth, overlayHeight);
        CGContextFillRect(context, overlayRect);
    }

    // X scale is set to show all values
    const CGFloat xinc = sparkWidth / ([self.dataValues count] - 1);
    
    // Y scale is auto-zoomed to specified limits (allowing for pen width)
    CGFloat yInc = (sparkHeight - self.penWidth) / (graphMax - graphMin);
    
    // ensure the pen is a suitable width for the device we are on (i.e. we use *pixels* and not points)
    if (self.penWidth) {
        CGContextSetLineWidth(context, self.penWidth / self.contentScaleFactor);
    } else {
        CGContextSetLineWidth(context, GRAPH_PEN_WIDTH / self.contentScaleFactor);
    }

    // Customisation to allow pencolour changes
    if (self.penColor) {
        [self.penColor setStroke];
    } else {
        [[UIColor PEN_COL] setStroke];
    }
    
    CGContextBeginPath(context);

    // iterate over the data items, plotting the graph path
    [self.dataValues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        const CGFloat xpos = (xinc * idx) + GRAPH_X_BORDER;
        CGFloat ypos = 0.0f;

        // warning and zero value for any non-NSNumber objects
        if ([obj isKindOfClass:[NSNumber class]]) {
            ypos = yPlotValue(fullHeight, yInc, [obj floatValue], graphMin, self.penWidth);
        } else {
            NSLog(@"non-NSNumber object (%@) found in data (index %d), zero value used", [[obj class] description], idx);
            ypos = yPlotValue(fullHeight, yInc, 0.0f, graphMin, self.penWidth);
        }

        if (idx > 0)
            CGContextAddLineToPoint(context, xpos, ypos);
        else
            CGContextMoveToPoint(context, xpos, ypos);
    }];

    // draw the graph line (path)
    CGContextStrokePath(context);

    // draw the value marker circle, if requested
    if (self.showCurrentValue) {

        const CGFloat markX = (xinc * ([self.dataValues count]-1)) + GRAPH_X_BORDER;
        const CGFloat markY = yPlotValue(fullHeight, yInc, [self.dataCurrentValue floatValue], graphMin, self.penWidth);

        // calculate the accent marker size, with limits
        CGFloat markSize = fullHeight * DEF_MARKER_SIZE_FRAC;
        if (markSize < MARKER_MIN_SIZE)
            markSize = MARKER_MIN_SIZE;
        else if (markSize > MARKER_MAX_SIZE)
            markSize = MARKER_MAX_SIZE;

        const CGRect markRect = CGRectMake(markX - (markSize/2.0f), markY - (markSize/2.0f), markSize, markSize);
        [self.currentValueColor setFill];
        CGContextFillEllipseInRect(context, markRect);
    }
}


// returns the Y plot value, given the limitations we have
static inline float yPlotValue(float maxHeight, float yInc, float val, float offset, float penWidth) {
    return maxHeight - ((yInc * (val - offset)) + GRAPH_Y_BORDER + (penWidth / 2.0f));
}

@end
