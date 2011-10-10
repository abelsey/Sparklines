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

/**
 \mainpage SparkLine Custom View
 
 Sparklines are small, word-sized graphics representing a time-series of data points, with optional range overlay and numeric
 display of the current (last) value. These were developed by Edward Tufte and described in his book <em>The Visual Display of
 Quantitative Information</em>, first published in 1982. Sparklines are meant to be concise and are not replacements for full
 graphical representations. They are ideal for showing lots of data series views, enabling the user to quickly gain an
 appreciation of the historical nature of the series represented.
 
 The X scale is auto-scaled to show all the values across the total width of the view frame. In the case where multiple views
 depict different series lengths, the programmer should take care that the series have similar numbers of data points,
 otherwise the user may be misled as to the total time period represented by the different views presented.
 
 The scale in the vertical (Y) direction is auto-scaled, and no scale marks are provided. The idea is that the sparkline shows
 the relative history, and not a definitive, scaled representation. In this implementation, you can alter the vertical scale by
 defining the upper and/or lower range overlay limits, which will force the graph to include those data values (even if you choose
 not to display the range overlay). Setting either of the lower or upper range overlay limits to \a nil will result in the graph
 using the respective minimum or maximum data values for the bounds of the graph scale.
 
 Below is a magnified example of how a sparkline might appear in print (i.e. this is not an exact example of how this custom view
 looks):
 
 \image html Sparklines.png
 
 This SparkLineView class implementation is for iOS devices, and accepts an \b NSArray of \b NSNumber objects representing the
 data series to be displayed. The graph is drawn with a suitable vertical scale so that can show all of the data and the range
 overlay limits (used to mark an 'acceptable' range for the data series). If the current value is displayed, it is marked on
 the graph with a coloured accent dot, to draw the user's eye to the value specified in the text label.
 
 There are a number of user-settable items in this view:
 
 \li the data series (as an \b NSArray of \b NSNumber objects)
 \li the label text for the sparkline
 \li flag to enable a numeric display of the current (last) value (default: yes)
 \li the colour of the current value (default: blue)
 \li the number format of the current value (default: %.1f)
 \li flag to enable display of a range overlay (default: no)
 \li the colour of the range overlay (default: light gray)
 \li the lower limit of the range overlay
 \li the upper limit of the range overlay
 
 There are also three read-only items:
 
 \li the current (last) value of the data series being displayed
 \li the minimum of the data series being displayed
 \li the maximum of the data series being displayed
 
 \note I use the American English spelling of 'color' in the Objective-C properties, to match that of the iOS frameworks.
 However, I revert to the British English spelling, 'colour', elsewhere for the simple reason that I'm British...
 
 \class ASBSparkLineView
 \brief A custom view to display a sparkline on an iOS device.
 
 To use this custom view, simply copy the \a ASBSparkLineView.h and \a ASBSparkLineView.m files into your project, and either
 create instances of the \a ASBSparkLineView class programmatically, or via Interface Builder (create a \b UIView object and
 change the class to be \a ASBSparkLineView).
 
 The length of the label text, and any numeric value shown, has a bearing on how much of the views's width is used to show the
 graphed data. The maximum fraction of the width used to show the whole text string is 50%, and if more is needed, the text will
 simply be truncated (at the right hand side). The font used is set, by default, to be Helvetica 12.0pts and is shrunk to a
 minimum of 10.0pts where a lot of text is needed to be shown. These limits can be changed by altering the constants at the top
 of the \a ASBSparkLineView.m implementation file. Exact values need some experimentation and are dependent on the size of the
 views employed.
 
 */

#import <UIKit/UIKit.h>

@interface ASBSparkLineView : UIView {

@private
    NSArray *m_dataValues;

    NSString *m_labelText;
    UIColor *m_labelColour;

    BOOL m_showCurrentValue;
    UIColor *m_currentValueColour;
    NSString *m_currentValueFormat;

    BOOL m_showRangeOverlay;
    UIColor *m_rangeOverlayColour;
    NSNumber *m_rangeOverlayLowerLimit;
    NSNumber *m_rangeOverlayUpperLimit;
    
    UIColor *m_penColor;
    CGFloat m_penWidth;

    NSNumber *m_dataMinimum;
    NSNumber *m_dataMaximum;
}

//! Holds the array of \b NSNumber values to display.
@property (nonatomic, retain) NSArray *dataValues;

//! The text to be displayed beside the graph data.
@property (nonatomic, copy) NSString *labelText;
//! The colour of the label text (default: dark gray).
@property (nonatomic, retain) UIColor *labelColor;

//! Flag to enable display of the numerical current (last) value (default: YES).
@property (nonatomic) BOOL showCurrentValue;
//! The UIColor used to display the numeric current value and the marker anchor.
@property (nonatomic, retain) UIColor *currentValueColor;
//! The format (in printf() style) of the numeric current value.
@property (nonatomic, copy) NSString *currentValueFormat;

//! Flag to enable the display of the range overlay (default: NO).
@property (nonatomic) BOOL showRangeOverlay;
//! The UIColor used for the range overlay.
@property (nonatomic, retain) UIColor *rangeOverlayColor;

//! The UIColor used for the sparkline colour itself
@property (nonatomic, retain) UIColor *penColor;

//! The float value used for the sparkline pen width
@property (nonatomic) CGFloat penWidth;


/**
 \brief The lower limit of the range overlay.
 
 If this is \a nil the range extends to the lower edge of the view (beyond the data). Note that setting this attribute to valid
 \b NSNumber will also define the lower limit of the vertical graph scale, i.e. the graph will be scaled to show either
 this limit, or the lowest data value, whichever is the minimum. This can be used, in conjunction with the upper limit,
 to force the graph's vertical scale to some desired value. Otherwise, the vertical scale is calculated to show the maximum and
 minimum data values at the edges, i.e. it is auto-scaled.
 */
@property (nonatomic, copy) NSNumber *rangeOverlayLowerLimit;

/**
 \brief The upper limit of the range overlay.
 
 If this is \a nil the range extends to the upper edge of the view (beyond the data). Note that setting this attribute to valid
 \b NSNumber will also define the upper limit of the vertical graph scale, i.e. the graph will be scaled to show either
 this limit, or the highest data value, whichever is the maximum. This can be used, in conjunction with the lower limit,
 to force the graph's vertical scale to some desired value. Otherwise, the vertical scale is calculated to show the maximum and
 minimum data values at the edges, i.e. it is auto-scaled.
 */
@property (nonatomic, copy) NSNumber *rangeOverlayUpperLimit;

//! Minimum data value found (read-only).
@property (nonatomic, copy, readonly) NSNumber *dataMinimum;
//! Maximum data value found (read-only).
@property (nonatomic, copy, readonly) NSNumber *dataMaximum;
//! The current (last) value of the data series.
@property (readonly) NSNumber *dataCurrentValue;


/**
 \brief Designated initializer.
 Initilizes a new instance of this class, and specifying the data array, frame and text label to use.
 \param data An \b NSArray of \b NSNumber objects representing the data to display.
 \param frame A \b CGRect defining the initial frame of the view.
 \param label An \b NSString defining the text label to use.
 \return The \b id of the created view object.
 */
- (id)initWithData:(NSArray *)data frame:(CGRect)frame label:(NSString *)label;

/**
 \brief Convienence initializer.
 Initilizes a new instance of this class, specifying the data and frame to use.
 The text label will be \a nil.
 \param data An \b NSArray of \b NSNumber objects representing the data to display.
 \param frame A \b CGRect defining the initial frame of the view.
 \return The \b id of the created view object.
 */
- (id)initWithData:(NSArray *)data frame:(CGRect)frame;

/**
 \brief Convienence initializer.
 Initilizes a new instance of this class, only specifying the frame.
 The data series will be initialized to an empty \b NSArray, and the text label will be \a nil.
 \param frame A \b CGRect defining the initial frame of the view.
 \return The \b id of the created view object.
 */
- (id)initWithFrame:(CGRect)frame;
@end
