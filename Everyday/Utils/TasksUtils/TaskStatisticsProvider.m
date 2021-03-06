//
// Created by Eliasz Sawicki on 10/07/15.
// Copyright (c) 2015 __eSAWProducts__. All rights reserved.
//

#import <DateTools/NSDate+DateTools.h>
#import "TaskStatisticsProvider.h"
#import "TaskStatistics.h"
#import "Task.h"
#import "TasksLoader.h"


@implementation TaskStatisticsProvider

+ (NSArray *)statisticsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {
    NSMutableArray *tasksDaysArray = [self tasksFromDate:fromDate toDate:toDate];

    NSMutableDictionary *doneDictionary = [self doneDictionaryFromTasks:tasksDaysArray];
    NSMutableDictionary *notDoneDictionary = [self notDoneDictionaryFromTasks:tasksDaysArray];

    NSMutableArray *resultArray = [self tasksStatisticsWithNotDoneDictionary:notDoneDictionary doneDictionary:doneDictionary];

    return resultArray;
}

+ (NSMutableArray *)tasksStatisticsWithNotDoneDictionary:(NSMutableDictionary *)notDoneDictionary doneDictionary:(NSMutableDictionary *)doneDictionary {
    NSArray *doneKeys = [doneDictionary allKeys];
    NSArray *notDoneKeys = [notDoneDictionary allKeys];

    NSMutableArray *resultArray = [NSMutableArray new];
    for (NSString *key in doneKeys) {
        NSInteger doneCount = [doneDictionary[key] integerValue];
        NSInteger notDoneCount = [notDoneDictionary[key] integerValue];

        TaskStatistics *taskStatistics = [TaskStatistics statisticsWithName:key doneCounter:doneCount notDoneCounter:notDoneCount];
        [resultArray addObject:taskStatistics];
    }

    for (NSString *key in notDoneKeys) {
        if (![doneKeys containsObject:key]) {
            NSInteger doneCount = [doneDictionary[key] integerValue];
            NSInteger notDoneCount = [notDoneDictionary[key] integerValue];

            TaskStatistics *taskStatistics = [TaskStatistics statisticsWithName:key doneCounter:doneCount notDoneCounter:notDoneCount];
            [resultArray addObject:taskStatistics];
        }
    }
    return resultArray;
}

+ (NSMutableDictionary *)notDoneDictionaryFromTasks:(NSMutableArray *)tasksDaysArray {
    NSMutableDictionary *notDoneDictionary = [NSMutableDictionary new];
    for (NSArray *array in tasksDaysArray) {
        for (Task *task in array) {
            if (!task.isDone) {
                NSNumber *taskCount = notDoneDictionary[task.name];
                notDoneDictionary[task.name] = @(taskCount.integerValue + 1);
            }
        }
    }
    return notDoneDictionary;
}

+ (NSMutableDictionary *)doneDictionaryFromTasks:(NSMutableArray *)tasksDaysArray {
    NSMutableDictionary *doneDictionary = [NSMutableDictionary new];
    for (NSArray *array in tasksDaysArray) {
        for (Task *task in array) {
            if (task.isDone) {
                NSNumber *taskCount = doneDictionary[task.name];
                doneDictionary[task.name] = @(taskCount.integerValue + 1);
            }
        }
    }
    return doneDictionary;
}

+ (NSMutableArray *)tasksFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {
    NSMutableArray *tasksDaysArray = [NSMutableArray new];
    while (fromDate.day <= toDate.day || fromDate.month <= toDate.month) {
        NSArray *tasks = [TasksLoader loadTasksForDate:fromDate];
        if (tasks != nil) {
            [tasksDaysArray addObject:tasks];
        }
        fromDate = [fromDate dateByAddingDays:1];
    }
    return tasksDaysArray;
}
@end