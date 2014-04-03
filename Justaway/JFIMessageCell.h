#import <UIKit/UIKit.h>

@interface JFIMessageCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *screenNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *displayNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UILabel *createdAtRelativeLabel;
@property (nonatomic, weak) IBOutlet UILabel *createdAtLabel;
@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;

- (void)setLabelTexts:(NSDictionary *)message;

@end