//
// Created by Eluss on 04/06/15.
// Copyright (c) 2015 __eSAWProducts__. All rights reserved.
//

#import <PureLayout/PureLayoutDefines.h>
#import <PureLayout/ALView+PureLayout.h>
#import "TasksTableViewDataSource.h"
#import "RACEXTScope.h"
#import "TasksDataSource.h"
#import "RACSignal.h"
#import "RACDisposable.h"
#import "Task.h"
#import "TasksTableView.h"
#import "FileChecker.h"
#import "TasksSaver.h"
#import "UIColor+Additions.h"
#import "Fonts.h"

@implementation TasksTableViewDataSource {

    NSArray *_dataArray;
    RACDisposable *_tasksSubscription;
    TasksDataSource *_fakeTasksDataSource;
    NSDate *_tasksDate;
    BOOL _hasNoFileForData;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _fakeTasksDataSource = [TasksDataSource new];
        [self updateTasksDataForDate:nil];
    }

    return self;
}

- (void)updateTasksDataForDate:(NSDate *)date {
    @weakify(self);
    [_tasksSubscription dispose];
    _tasksSubscription = [[_fakeTasksDataSource tasksForDate:date] subscribeNext:^(NSArray *tasks) {
        @strongify(self);
        self->_tasksDate = date;
        self->_dataArray = tasks;
    }];
}

- (id)initWithDate:(NSDate *)date {
    self = [super init];
    if (self) {
        _tasksDate = date;
        _fakeTasksDataSource = [TasksDataSource new];
        [self updateTasksDataForDate:date];
    }

    return self;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_hasNoFileForData) {
        return 0;
    } else {
        return [_dataArray count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = @"taskCell";
    MCSwipeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
//    cell.contentView.backgroundColor = UIColorFromRGB(0xC9F6FF);
    CGFloat height = 60;
    UIView *leftSwipeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, height)];
    leftSwipeView.backgroundColor = [UIColor everydayGreenColor];

    UIView *rightSwipeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, height)];
    rightSwipeView.backgroundColor = [UIColor everydayRedColor];

    Task *cellTask = _dataArray[(NSUInteger) indexPath.row];

    cell.textLabel.text = cellTask.name;
    cell.textLabel.font = [Fonts cellFont];


    UIColor *color = [UIColor everydayGreenColor];
    @weakify(self);
    [cell setSwipeGestureWithView:leftSwipeView color:color mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState1 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
        @strongify(self);
        [cellTask changeState];
        [self updateCell:cell forTask:cellTask];
    }];

    UIColor *deletionColor = [UIColor everydayRedColor];
    [cell setSwipeGestureWithView:rightSwipeView color:deletionColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState3 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
        @strongify(self);
        self->_deletionBlock(cell, state, mode);
    }];

    [self updateCell:cell forTask:cellTask];

    return cell;


}


- (void)updateCell:(MCSwipeTableViewCell *)cell forTask:(Task *)task {
    if (task.isDone) {
        cell.contentView.backgroundColor = [UIColor everydayGreenColor];
//        cell.textLabel.textColor = [UIColor lightGrayColor];
    } else {
        cell.contentView.backgroundColor = [UIColor everydayRedColor];
//        cell.textLabel.textColor = [UIColor blackColor];
    }

    [self saveArray];
}

- (void)dealloc {
    [_tasksSubscription dispose];
}

- (void)saveArray {
    [TasksSaver saveTasks:_dataArray ForDate:_tasksDate];
}


- (void)addCustomRowWithName:(NSString *)name {
    NSMutableArray *array = [_dataArray mutableCopy];
    if (!array) {
        array = [NSMutableArray new];
    }
    Task *task = [[Task alloc] initWithName:name isDone:NO];
    [array insertObject:task atIndex:0];
    _dataArray = array;
}

- (void)removeDataAtIndexPath:(NSIndexPath *)path {
    NSMutableArray *array = [_dataArray mutableCopy];
    [array removeObjectAtIndex:(NSUInteger) path.row];
    _dataArray = array;
}

- (void)hideAllCells {
    _hasNoFileForData = YES;
}

- (void)showAllCells {
    _hasNoFileForData = NO;
}

- (BOOL)isShowingCells {
    return !_hasNoFileForData;
}

- (UIView *)showMessageOnTableView {
    UIView *messageView = [UIView new];
    UILabel *messageLabel = [UILabel new];

    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
    messageLabel.numberOfLines = 0;
    messageLabel.font = [Fonts headerFont];

    messageLabel.text = @"Tap the screen to add this day to statistics";
    [messageView addSubview:messageLabel];

    [messageLabel autoPinEdgesToSuperviewEdgesWithInsets:ALEdgeInsetsZero];

    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapTableViewBackground)];
    [messageView addGestureRecognizer:gestureRecognizer];

    return messageView;
}

- (void)didTapTableViewBackground {
    if (![self isShowingCells]) {
        self.tableView.backgroundView = nil;
        [self showAllCells];
        [self updateTasksDataForDate:_tasksDate];
        [self.tableView reloadData];
    }
}

- (void)showMessageIfDateHasNoRecordedData {
    BOOL fileExists = [FileChecker fileExistsForDate:_tasksDate];
    [self updateTasksDataForDate:_tasksDate];
    if (fileExists) {
        self.tableView.backgroundView = nil;
        [self showAllCells];
        [self updateTasksDataForDate:_tasksDate];
        [self.tableView reloadData];
    } else {
        self.tableView.backgroundView = [self showMessageOnTableView];
        [self hideAllCells];
        [self.tableView reloadData];
    }
}


@end