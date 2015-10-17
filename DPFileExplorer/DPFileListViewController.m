#import "DPFileListViewController.h"
#import "DPFileListTableViewCell.h"


@interface DPFileListViewController () <UIAlertViewDelegate, UIActionSheetDelegate, UIDocumentInteractionControllerDelegate>
{
    NSMutableArray*      _fileURLs;
    NSMutableDictionary* _fileWrappers;
    UIRefreshControl*    _refreshControl;
    
    UIDocumentInteractionController* _documentInteractionController;
    
    __weak UIAlertView* _deleteConfirm;
    __weak UIAlertView* _renameConfirm;
    __weak UIAlertView* _mkdirConfirm;
    UIBarButtonItem*    _mkdirButton;
}
@property (nonatomic, copy) NSArray* fileURLs;
@property NSURL* parentFileURL;
@end


@implementation DPFileListViewController

#pragma mark - Initializer

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _fileWrappers = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Editing
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // RefreshControl
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(valueChangedRefreshControl:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = _refreshControl;
    
    // Custom TableViewCell
    [self.tableView registerNib:[DPFileListTableViewCell nibForRegisterTableView] forCellReuseIdentifier:DPFileListTableViewCellIdentifier];
    
    // for mkdir
    _mkdirButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(actionForMkdirBarButtonItem:)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    for (NSIndexPath* indexPath in self.tableView.indexPathsForSelectedRows) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:animated];
    }
}

#pragma mark - Accessor

- (NSArray*)fileURLs
{
    return _fileURLs.copy;
}

- (void)setFileURLs:(NSArray*)fileURLs
{
    if ([_fileURLs isEqualToArray:fileURLs] == NO) {
        for (id obj in fileURLs) {
            if ([obj isKindOfClass:[NSURL class]] == NO || [obj isFileURL] == NO) {
                [NSException raise:@"TypeException" format:@"each fileURL object must be NSFileURL instance. and must be isFileURL==YES"];
            }
        }
        
        _fileURLs = fileURLs.mutableCopy;
        
        [_fileWrappers removeAllObjects];
        for (NSURL* url in fileURLs) {
            NSError* error;
            NSFileWrapper* fw = [[NSFileWrapper alloc] initWithURL:url options:NSFileWrapperReadingWithoutMapping error:&error];
            if (error) {
                NSLog(@"error\n%@", error);
            }
            if (fw) {
                _fileWrappers[url] = fw;
            }
        }
        
        if (self.isViewLoaded) {
            [self.tableView reloadData];
        }
    }
}

#pragma mark - UIRefreshControl Action

- (void)valueChangedRefreshControl:(UIRefreshControl*)refreshControl
{
    if (self.editing) {
        [refreshControl endRefreshing];
        return;
    }
    
    NSArray* fileURLs;
    if (self.parentFileURL) {
        NSError* error;
        fileURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.parentFileURL includingPropertiesForKeys:nil options:0 error:&error];
        if (error) {
            [self showErrorAlertWithError:error];
        }
    } else {
        fileURLs = [[self class] rootFileURLs];
    }
    self.fileURLs = fileURLs;
    [refreshControl endRefreshing];
}

#pragma mark - UIBarButtonItem Action

- (void)actionForMkdirBarButtonItem:(UIBarButtonItem*)barButtonItem
{
    UIAlertView* mkdirConfirm = [[UIAlertView alloc] initWithTitle:@"mkdir" message:@"enter new directory name." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"mkdir", nil];
    mkdirConfirm.alertViewStyle = UIAlertViewStylePlainTextInput;
    _mkdirConfirm = mkdirConfirm;
    [mkdirConfirm show];
}

#pragma mark - Editing

- (void)setEditing:(BOOL)editing
{
    [self setEditing:editing animated:NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.navigationItem setHidesBackButton:editing animated:animated];
    self.refreshControl = (editing ? nil : _refreshControl);
    [self.navigationItem setLeftBarButtonItem:(editing && self.parentFileURL ? _mkdirButton : nil) animated:animated];
    for (UITableViewCell* cell in self.tableView.visibleCells) {
        [cell setEditing:editing animated:animated];
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    DPFileListTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:DPFileListTableViewCellIdentifier];
    cell.fileWrapper = _fileWrappers[_fileURLs[indexPath.row]];
    cell.editing = self.editing;
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return _fileURLs.count;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
    return (self.parentFileURL != nil);
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        UIAlertView* deleteConfirm = [[UIAlertView alloc] initWithTitle:@"Are you sure?" message:@"Delete file?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
        deleteConfirm.tag = indexPath.row;
        _deleteConfirm = deleteConfirm;
        [deleteConfirm show];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (self.editing) {
        UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Action" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:@"Rename", nil];
        actionSheet.tag = indexPath.row;
        [actionSheet showInView:self.view];
    }
    else {
        NSURL* fileURL = _fileURLs[indexPath.row];
        NSFileWrapper* fw = _fileWrappers[fileURL];
        if (fw.isDirectory) {
            NSError* error;
            NSArray* fileURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:fileURL includingPropertiesForKeys:nil options:0 error:&error];
            if (error) {
                [self showErrorAlertWithError:error];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
            else {
                typeof(self) vc = [[[self class] alloc] initWithNibName:nil bundle:nil];
                vc.fileURLs = fileURLs;
                vc.parentFileURL = fileURL;
                vc.title = fw.filename;
                [self.navigationController pushViewController:vc animated:YES];
            }
        }
        else {
            UIDocumentInteractionController* documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
            documentInteractionController.delegate = self;
            // BOOL success = [documentInteractionController presentOpenInMenuFromRect:self.view.frame inView:self.view animated:YES];
            BOOL success = [documentInteractionController presentOptionsMenuFromRect:self.view.frame inView:self.view animated:YES];
            if (success) {
                _documentInteractionController = documentInteractionController;
            }
            else {
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
        }
    }
}

#pragma mark - Show Error

- (void)showErrorAlertWithError:(NSError*)error
{
    NSLog(@"error\n%@", error);
    [[[UIAlertView alloc] initWithTitle:@"Error!" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:alertView.tag inSection:0];
    
    // Delete
    if (alertView == _deleteConfirm) {
        if (buttonIndex == 1) {
            NSURL* fileURL = _fileURLs[indexPath.row];
            NSError* error;
            [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error];
            if (error) {
                [self showErrorAlertWithError:error];
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
            else {
                [_fileURLs removeObject:fileURL];
                [_fileWrappers removeObjectForKey:fileURL];
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
        else {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
    
    // Rename
    else if (alertView == _renameConfirm) {
        if (buttonIndex == 1) {
            NSURL* fileURL = _fileURLs[indexPath.row];
            NSString* newFileName = [alertView textFieldAtIndex:0].text;
            NSString* newFilePath = [[fileURL.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFileName];
            NSURL*    newFileURL  = [NSURL fileURLWithPath:newFilePath];
            NSError* error;
            [[NSFileManager defaultManager] moveItemAtURL:fileURL toURL:newFileURL error:&error];
            if (error) {
                [self showErrorAlertWithError:error];
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
            else {
                NSFileWrapper* newFw = [[NSFileWrapper alloc] initWithURL:newFileURL options:NSFileWrapperReadingWithoutMapping error:&error];
                if (error) {
                    [self showErrorAlertWithError:error];
                    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                }
                if (newFw) {
                    [_fileURLs replaceObjectAtIndex:indexPath.row withObject:newFileURL];
                    [_fileWrappers removeObjectForKey:fileURL];
                    [_fileWrappers setObject:newFw forKey:newFileURL];
                    DPFileListTableViewCell* cell = (DPFileListTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
                    cell.fileWrapper = newFw;
                    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                }
            }
        }
        else {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
    
    // mkdir
    else if (alertView == _mkdirConfirm) {
        if (buttonIndex == 1) {
            indexPath = [NSIndexPath indexPathForRow:_fileURLs.count inSection:0];
            NSString* newDirectoryName = [alertView textFieldAtIndex:0].text;
            NSString* newDirectoryPath = [self.parentFileURL.path stringByAppendingPathComponent:newDirectoryName];
            NSURL*    newDirectoryURL  = [NSURL fileURLWithPath:newDirectoryPath];
            NSError* error;
            [[NSFileManager defaultManager] createDirectoryAtURL:newDirectoryURL withIntermediateDirectories:NO attributes:nil error:&error];
            if (error) {
                [self showErrorAlertWithError:error];
            }
            else {
                NSFileWrapper* newFw = [[NSFileWrapper alloc] initWithURL:newDirectoryURL options:NSFileWrapperReadingWithoutMapping error:&error];
                if (error) {
                    [self showErrorAlertWithError:error];
                }
                if (newFw) {
                    [_fileURLs addObject:newDirectoryURL];
                    [_fileWrappers setObject:newFw forKey:newDirectoryURL];
                    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            }
        }
    }
    
    // Undefined
    else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:actionSheet.tag inSection:0];
    
    // Delete
    if (buttonIndex == 0) {
        UIAlertView* deleteConfirm = [[UIAlertView alloc] initWithTitle:@"Are you sure?" message:@"Delete file?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
        deleteConfirm.tag = indexPath.row;
        _deleteConfirm = deleteConfirm;
        [deleteConfirm show];
    }
    
    // Rename
    else if (buttonIndex == 1) {
        UIAlertView* renameConfirm = [[UIAlertView alloc] initWithTitle:@"Rename" message:@"enter new file name." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Rename", nil];
        renameConfirm.tag = indexPath.row;
        renameConfirm.alertViewStyle = UIAlertViewStylePlainTextInput;
        NSURL* fileURL = _fileURLs[indexPath.row];
        [renameConfirm textFieldAtIndex:0].text = fileURL.pathComponents.lastObject;
        _renameConfirm = renameConfirm;
        [renameConfirm show];
    }
    
    // Undefined
    else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate

/*
- (void)documentInteractionControllerWillPresentOptionsMenu:(UIDocumentInteractionController*)controller
{
    
}
 */

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController*)controller
{
    if (controller == _documentInteractionController) {
        for (NSIndexPath* indexPath in self.tableView.indexPathsForSelectedRows) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
}

/*
- (void)documentInteractionControllerWillPresentOpenInMenu:(UIDocumentInteractionController*)controller
{
    
}
 */

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController*)controller
{
    if (controller == _documentInteractionController) {
        for (NSIndexPath* indexPath in self.tableView.indexPathsForSelectedRows) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
}

- (void)documentInteractionController:(UIDocumentInteractionController*)controller willBeginSendingToApplication:(NSString*)application // bundle ID
{
    if (controller == _documentInteractionController) {
        NSLog(@"%@, application -> %@", NSStringFromSelector(_cmd), application);
    }
}

- (void)documentInteractionController:(UIDocumentInteractionController*)controller didEndSendingToApplication:(NSString*)application
{
    if (controller == _documentInteractionController) {
        _documentInteractionController = nil;
    }
}

#pragma mark - RootFileList

+ (NSArray*)rootFileURLs
{
    /*
    NSSearchPathDirectory directories[] = {
        NSApplicationDirectory,
        NSDemoApplicationDirectory,
        NSDeveloperApplicationDirectory,
        NSAdminApplicationDirectory,
        NSLibraryDirectory,
        NSDeveloperDirectory,
        NSUserDirectory,
        NSDocumentationDirectory,
        NSDocumentDirectory,
        NSCoreServiceDirectory,
        NSAutosavedInformationDirectory,
        NSDesktopDirectory,
        NSCachesDirectory,
        NSApplicationSupportDirectory,
        NSDownloadsDirectory,
        NSInputMethodsDirectory,
        NSMoviesDirectory,
        NSMusicDirectory,
        NSPicturesDirectory,
        NSPrinterDescriptionDirectory,
        NSSharedPublicDirectory,
        NSPreferencePanesDirectory,
        NSItemReplacementDirectory,
        NSAllApplicationsDirectory,
        NSAllLibrariesDirectory
    };
    uint16_t directoriesCount = 25;
     */
    
    NSMutableArray* fileURLs = [NSMutableArray array];
    {
        NSSearchPathDirectory directories[] = {
            NSLibraryDirectory,
            NSDocumentDirectory,
            NSCachesDirectory,
        };
        uint16_t directoriesCount = 3;
        for (int i = 0; i < directoriesCount; i++) {
            for (NSString* path in NSSearchPathForDirectoriesInDomains(directories[i], NSUserDomainMask, YES)) {
                NSURL* fileURL = [NSURL fileURLWithPath:path];
                if (fileURL && [fileURLs containsObject:fileURL] == NO) {
                    [fileURLs addObject:fileURL];
                }
            }
        }
    }
    return fileURLs.copy;
}

+ (instancetype)rootFileListViewController
{
    DPFileListViewController* rootFileListViewController = [[self alloc] initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle mainBundle]];
    rootFileListViewController.fileURLs = [self rootFileURLs];
    rootFileListViewController.title = @"Root";
    return rootFileListViewController;
}

@end
