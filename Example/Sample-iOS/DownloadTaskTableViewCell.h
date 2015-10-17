#import <UIKit/UIKit.h>


extern NSString* const DownloadTaskTableViewCellReuseIdentifier;


@class DPFileDownloadTask;


@interface DownloadTaskTableViewCell : UITableViewCell
@property (nonatomic) DPFileDownloadTask* fileDownloadTask;
@end
