#import "MenuTableViewController.h"
#import "DPFileListViewController.h"


@interface MenuTableViewController ()

@end


@implementation MenuTableViewController

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == 1 && indexPath.row == 0) {
        [self.navigationController pushViewController:[DPFileListViewController rootFileListViewController] animated:YES];
    }
}

@end
