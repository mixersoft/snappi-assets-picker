//
//  FloatingTrayView.h
//  Knotable
//
//  Created by Martin Ceperley on 1/17/14.
//
//

@protocol FloatingTrayDelegate

@optional

-(void)floatingTrayNext;
-(void)floatingTrayPrev;

@end

@interface FloatingTrayView : UIView

-(void)installConstraints;

@property (nonatomic, weak) NSObject<FloatingTrayDelegate>* delegate;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIButton *prevButton;

@end
