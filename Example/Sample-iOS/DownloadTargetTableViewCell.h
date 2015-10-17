#import <UIKit/UIKit.h>


extern NSString* const DownloadTargetTableViewCellReuseIdentifier;


@interface DownloadTargetTableViewCell : UITableViewCell
@property (nonatomic) NSDictionary* downloadTarget;
@end
