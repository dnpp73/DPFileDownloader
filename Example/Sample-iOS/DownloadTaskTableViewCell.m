#import "DownloadTaskTableViewCell.h"
#import "DPFileDownloadTask.h"
#import "DPFileDownloader.h"


NSString* const DownloadTaskTableViewCellReuseIdentifier = @"DownloadTaskTableViewCellReuseIdentifier";


@interface DownloadTaskTableViewCell () <DPFileDownloadTaskObserving>
@property (weak, nonatomic) IBOutlet UILabel*  progressLanel;
@property (weak, nonatomic) IBOutlet UILabel*  label;
@property (weak, nonatomic) IBOutlet UIButton* pauseResumeButton;
@property (weak, nonatomic) IBOutlet UIButton* cancelButton;
@end


@implementation DownloadTaskTableViewCell

- (void)setFileDownloadTask:(DPFileDownloadTask*)fileDownloadTask
{
    if (_fileDownloadTask != fileDownloadTask) {
        [_fileDownloadTask removeFileDownloadTaskObserver:self];
        _fileDownloadTask = fileDownloadTask;
        [fileDownloadTask addFileDownloadTaskObserver:self];
        [self updateUserInterfaceValues];
    }
}

- (void)updateUserInterfaceValues
{
    NSString* state    = [NSString stringWithFormat:@"(%d)", (int)self.fileDownloadTask.state];
    NSString* progress = (self.fileDownloadTask.state == DPFileDownloadTaskStateDownloading || self.fileDownloadTask.state == DPFileDownloadTaskStatePausing) ? [NSString stringWithFormat:@" %.1f %%", self.fileDownloadTask.progress*100.0] : @"";
    
    self.progressLanel.text = progress;
    self.label.text = [NSString stringWithFormat:@"%@ %@", state, self.fileDownloadTask.expectedFileName];
    
    NSString* title = self.fileDownloadTask.state == DPFileDownloadTaskStatePausing ? @"Resume" : @"Pause";
    [self.pauseResumeButton setTitle:title forState:UIControlStateNormal];
    
    if (self.fileDownloadTask.state == DPFileDownloadTaskStateDownloadSuccess || self.fileDownloadTask.state == DPFileDownloadTaskStateDownloadFail) {
        self.pauseResumeButton.hidden = YES;
        self.cancelButton.hidden = YES;
    } else {
        self.pauseResumeButton.hidden = NO;
        self.cancelButton.hidden = NO;
    }
}

- (IBAction)touchUpInsidePauseResumeButton:(UIButton*)sender
{
    DPFileDownloadTask* task = self.fileDownloadTask;
    if (task.state == DPFileDownloadTaskStatePausing) {
        [[DPFileDownloader sharedDownloader] resumeFileDownloadTask:task];
    }
    else {
        [[DPFileDownloader sharedDownloader] pauseFileDownloadTask:task];
    }
}

- (IBAction)touchUpInsideCancelButton:(UIButton*)sender
{
    DPFileDownloadTask* task = self.fileDownloadTask;
    [[DPFileDownloader sharedDownloader] cancelFileDownloadTask:task];
}

#pragma mark - DPFileDownloadTaskObserving

- (void)fileDownloadTaskDidChangeState:(DPFileDownloadTask*)fileDownloadTask beforeState:(DPFileDownloadTaskState)beforeState
{
    if (fileDownloadTask == _fileDownloadTask) {
        [self updateUserInterfaceValues];
    }
}

- (void)fileDownloadTaskDidUpdateProgress:(DPFileDownloadTask*)fileDownloadTask
{
    if (fileDownloadTask == _fileDownloadTask) {
        [self updateUserInterfaceValues];
    }
}

@end
