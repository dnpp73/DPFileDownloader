#import "DownloaderTableViewController.h"
#import "DownloadTaskTableViewCell.h"
#import "DownloadTargetTableViewCell.h"

#import "DPFileDownloader.h"
#import "DPFileDownloadTask.h"


@interface DownloaderTableViewController () <DPFileDownloaderObserving>
{
    NSArray*        _downloadTargets;
    NSMutableArray* _sectionHeaders;
}
@end


@implementation DownloaderTableViewController

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[DPFileDownloader sharedDownloader] addFileDownloaderObserver:self];
    
    _downloadTargets = [NSArray arrayWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"SampleFileList" withExtension:@"plist"]];
    
    {   // sectionHeader
        UIView* (^sectionHeaderMaker)(NSString*) = ^(NSString* text){
            UIView* sectionHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 36)];
            sectionHeader.backgroundColor = [UIColor colorWithWhite:1.000 alpha:0.9];
            UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(10, 4, 320, 24)];
            label.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            label.backgroundColor = [UIColor clearColor];
            label.font = [UIFont systemFontOfSize:16];
            label.textColor = [UIColor colorWithWhite:0.467 alpha:1.000];
            label.text = text;
            [sectionHeader addSubview:label];
            if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
                sectionHeader.backgroundColor = [UIColor clearColor];
                UIVisualEffect* visualEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
                UIVisualEffectView* veview = [[UIVisualEffectView alloc] initWithEffect:visualEffect];
                veview.frame = sectionHeader.bounds;
                veview.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
                [sectionHeader addSubview:veview];
                [veview addSubview:label];
            }
            return sectionHeader;
        };
        _sectionHeaders  = [NSMutableArray arrayWithObjects:
                            sectionHeaderMaker(@"History Tasks"),
                            sectionHeaderMaker(@"Operating Tasks"),
                            sectionHeaderMaker(@"Queued Tasks"),
                            sectionHeaderMaker(@"Targets"),
                            nil];
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStyleBordered target:self action:@selector(pushClearButton:)];
}

#pragma mark - IBActions

- (IBAction)valueChangedRefreshControl:(UIRefreshControl*)sender
{
    [self.tableView reloadData];
    [sender endRefreshing];
}

#pragma mark - UITableView DataSource Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if      (section == 0) {
        return [DPFileDownloader sharedDownloader].historyOfFileDownloadTasks.count;
    }
    else if (section == 1) {
        return [DPFileDownloader sharedDownloader].operatingFileDownloadTasks.count;
    }
    else if (section == 2) {
        return [DPFileDownloader sharedDownloader].queuedFileDownloadTasks.count;
    }
    else if (section == 3) {
        return _downloadTargets.count;
    }
    else {
        return 0;
    }
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == 0) {
        DownloadTaskTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:DownloadTaskTableViewCellReuseIdentifier forIndexPath:indexPath];
        DPFileDownloadTask* task = [DPFileDownloader sharedDownloader].historyOfFileDownloadTasks[indexPath.row];
        cell.fileDownloadTask = task;
        return cell;
    }
    else if (indexPath.section == 1) {
        DownloadTaskTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:DownloadTaskTableViewCellReuseIdentifier forIndexPath:indexPath];
        DPFileDownloadTask* task = [DPFileDownloader sharedDownloader].operatingFileDownloadTasks[indexPath.row];
        cell.fileDownloadTask = task;
        return cell;
    }
    else if (indexPath.section == 2) {
        DownloadTaskTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:DownloadTaskTableViewCellReuseIdentifier forIndexPath:indexPath];
        DPFileDownloadTask* task = [DPFileDownloader sharedDownloader].queuedFileDownloadTasks[indexPath.row];
        cell.fileDownloadTask = task;
        return cell;
    }
    else if (indexPath.section == 3) {
        DownloadTargetTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:DownloadTargetTableViewCellReuseIdentifier forIndexPath:indexPath];
        cell.downloadTarget = _downloadTargets[indexPath.row];
        return cell;
    }
    else {
        return nil;
    }
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    return _sectionHeaders[section];
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    return 36;
}

#pragma mark - DPFileDownloaderObserving

- (void)fileDownloader:(DPFileDownloader*)fileDownloader didUpdateOperationOfFileDownloadTask:(DPFileDownloadTask*)task
{
    [self.tableView reloadData];
}

#pragma mark -

- (void)pushClearButton:(UIBarButtonItem*)sender
{
    [[DPFileDownloader sharedDownloader] clearFileDownloadHistory];
    [self.tableView reloadData];
}

@end
