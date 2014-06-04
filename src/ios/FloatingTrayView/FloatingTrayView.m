//
//  FloatingTrayView.m
//  Knotable
//
//  Created by Martin Ceperley on 1/17/14.
//
//

#import "FloatingTrayView.h"
#import "Masonry.h"

#import "UIButton+Extensions.h"

static const float WIDTH = 40.0;
static const float HEIGHT = 40.0;

static const float LEFT_PADDING = 100.0;
static const float RIGHT_PADDING = 20.0;
static const float BOTTOM_PADDING = 80.0;

@interface FloatingTrayView ()

@property (nonatomic, assign) BOOL animating;
@property (nonatomic, assign) BOOL expanded;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;


@property (nonatomic, strong) UIImageView *leftArrowImage;

@property (nonatomic, strong) MASConstraint *widthConstraint;
@property (nonatomic, strong) MASConstraint *leftConstraint;

@end

@implementation FloatingTrayView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
        self.layer.cornerRadius = 6.0;
        self.clipsToBounds = YES;

        self.expanded = NO;
        self.animating = NO;

        _leftArrowImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"left-arrow-white"]];
        [self addSubview:_leftArrowImage];

        _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
        [self addGestureRecognizer:_tapRecognizer];

        self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.nextButton addTarget:self action:@selector(nextPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.nextButton setImage:[UIImage imageNamed:@"down-arrow-white"] forState:UIControlStateNormal];
        [self.nextButton setContentEdgeInsets:UIEdgeInsetsMake(8, 8, 8, 8)];



        self.prevButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.prevButton addTarget:self action:@selector(prevPressed:) forControlEvents:UIControlEventTouchUpInside];

        [self.prevButton setImage:[UIImage imageNamed:@"up-arrow-white"] forState:UIControlStateNormal];
        [self.prevButton setContentEdgeInsets:UIEdgeInsetsMake(8, 8, 8, 8)];

    }
    return self;
}

-(void)nextPressed:(UIButton *)button
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(floatingTrayNext)]){
        [self.delegate floatingTrayNext];
    }
}

-(void)prevPressed:(UIButton *)button
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(floatingTrayPrev)]){
        [self.delegate floatingTrayPrev];
    }
}

-(void)installConstraints
{
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(HEIGHT));
        self.widthConstraint = make.width.equalTo(@(WIDTH));
        make.right.equalTo(@(-RIGHT_PADDING));
        make.bottom.equalTo(@(-BOTTOM_PADDING));
    }];

    [_leftArrowImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(@0.0);
        make.right.equalTo(@-8.0);
    }];
}


-(void)tapped:(UITapGestureRecognizer *)recognizer
{
    if(!_expanded){
        [self.widthConstraint uninstall];
        [self mas_makeConstraints:^(MASConstraintMaker *make) {
            self.leftConstraint = make.left.equalTo(@(LEFT_PADDING));
        }];

        self.nextButton.alpha = 0.0;
        self.prevButton.alpha = 0.0;
        
        [self addSubview:self.nextButton];
        [self addSubview:self.prevButton];

        [self.nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(@0.0);
            make.left.equalTo(@30.0);
        }];
        [self.prevButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(@0.0);
            make.left.equalTo(self.nextButton.mas_right).with.offset(15.0);
        }];

    } else {
        //[self removeInterface];
        [self.leftConstraint uninstall];
        [self mas_makeConstraints:^(MASConstraintMaker *make) {
            self.widthConstraint = make.width.equalTo(@(WIDTH));
        }];
    }

    self.animating = YES;
    self.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.3
                          delay:0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.2
                        options:0
                     animations:^{

                         if(!_expanded){
                             self.nextButton.alpha = 1.0;
                             self.prevButton.alpha = 1.0;


                             _leftArrowImage.transform = CGAffineTransformMakeRotation(M_PI);
                         } else {
                             self.nextButton.alpha = 0.0;
                             self.prevButton.alpha = 0.0;

                             
                             _leftArrowImage.transform = CGAffineTransformMakeRotation(0.0);

                         }

                         [self layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         self.expanded = !self.expanded;
                         self.animating = NO;
                         self.userInteractionEnabled = YES;


                         if(!self.expanded){
                             [self.nextButton removeFromSuperview];
                             [self.prevButton removeFromSuperview];
                         }

                     }];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
