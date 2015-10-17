#import "DownloadTargetTableViewCell.h"
#import "DPFileDownloadTask.h"
#import "DPFileDownloader.h"


NSString* const DownloadTargetTableViewCellReuseIdentifier = @"DownloadTargetTableViewCellReuseIdentifier";


@interface DownloadTargetTableViewCell ()
@property (weak, nonatomic) IBOutlet UILabel*  label;
@property (weak, nonatomic) IBOutlet UIButton* button;
@end


@implementation DownloadTargetTableViewCell

- (void)setDownloadTarget:(NSDictionary*)downloadTarget
{
    if ([_downloadTarget isEqualToDictionary:downloadTarget] == NO) {
        _downloadTarget = downloadTarget;
        self.label.text = downloadTarget[@"name"];
    }
}

- (IBAction)touchUpInsideButton:(UIButton*)sender
{
    NSDictionary* dt   = self.downloadTarget;
    NSString*     name = dt[@"name"];
    NSURL*        url  = [NSURL URLWithString:dt[@"url"]];
    NSURLRequest* req  = [NSURLRequest requestWithURL:url];
    
    NSArray*  paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentDirectoryPath = paths[0];
    
    DPFileDownloadTask* task = [[DPFileDownloadTask alloc] initWithURLRequest:req];
    task.expectedDirectoryPath = documentDirectoryPath;
    task.expectedFileName = name;
    [[DPFileDownloader sharedDownloader] enqueueFileDownloadTask:task];
}

@end
