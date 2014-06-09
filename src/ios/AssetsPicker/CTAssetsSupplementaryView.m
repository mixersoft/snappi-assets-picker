/*
 CTAssetsSupplementaryView.m
 
 The MIT License (MIT)
 
 Copyright (c) 2013 Clement CN Tsang
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import "CTAssetsSupplementaryView.h"

#define kIndicatorSize      30.0
#define kSideMargin         10.0
#define kGap                10.0


@interface CTAssetsSupplementaryView ()

@property (nonatomic, strong) NSLayoutConstraint *relateConstratint;
@property (nonatomic, strong) NSLayoutConstraint *centerConstraint;

@end





@implementation CTAssetsSupplementaryView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _label = [self supplementaryLabel];
        [self addSubview:_label];
        
        _indicator = [self activityIndicator];
        [self addSubview:_indicator];
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_indicator attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0f constant:kSideMargin]];
        
        _relateConstratint = [NSLayoutConstraint constraintWithItem:_label
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:_indicator
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1.0f
                                                           constant:kGap];
        _centerConstraint = [NSLayoutConstraint constraintWithItem:_label
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0f
                                                           constant:0.0f];
        
        [self addConstraint:_relateConstratint];
    }
    
    return self;
}

- (UILabel *)supplementaryLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(self.bounds, 8.0, 8.0)];
    label.font = [UIFont systemFontOfSize:18.0];
    label.textAlignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    return label;
}

- (UIActivityIndicatorView *)activityIndicator
{
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(self.bounds.origin.x + kSideMargin, self.bounds.origin.y + kSideMargin, kIndicatorSize, self.bounds.size.height - kSideMargin * 2)];
    [activityIndicator setColor:[UIColor blackColor]];
    
    return activityIndicator;
}

- (void)bind:(NSArray *)assets isLoading:(BOOL)isLoading
{
    /*
    NSInteger numberOfVideos = [assets filteredArrayUsingPredicate:[self predicateOfAssetType:ALAssetTypeVideo]].count;
    NSInteger numberOfPhotos = [assets filteredArrayUsingPredicate:[self predicateOfAssetType:ALAssetTypePhoto]].count;
    
    if (numberOfVideos == 0)
        self.label.text = [NSString stringWithFormat:NSLocalizedString(@"%ld Photos", nil), (long)numberOfPhotos];
    else if (numberOfPhotos == 0)
        self.label.text = [NSString stringWithFormat:NSLocalizedString(@"%ld Videos", nil), (long)numberOfVideos];
    else
        self.label.text = [NSString stringWithFormat:NSLocalizedString(@"%ld Photos, %ld Videos", nil), (long)numberOfPhotos, (long)numberOfVideos];
     */
    if (isLoading)
    {
        [_indicator setHidden:NO];
        [self removeConstraint:_centerConstraint];
        [self addConstraint:_relateConstratint];
        [_indicator startAnimating];
        
        self.label.text = [NSString stringWithFormat:NSLocalizedString(@"Loading", nil)];
    }
    else
    {
        [self removeConstraint:_relateConstratint];
        [self addConstraint:_centerConstraint];
        
        [_indicator stopAnimating];
        [_indicator setHidden:YES];
        
        self.label.text = [NSString stringWithFormat:NSLocalizedString(@"%ld Assets", nil), (long)assets.count];
    }
}

- (NSPredicate *)predicateOfAssetType:(NSString *)type
{
    return [NSPredicate predicateWithBlock:^BOOL(ALAsset *asset, NSDictionary *bindings) {
        return [[asset valueForProperty:ALAssetPropertyType] isEqual:type];
    }];
}

@end