//
//  ChatViewController.h
//  ChatTest
//
//  Created by WellPledge LLC on 8/20/15.
//  Copyright (c) 2015 Vikas Shah. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <JSQMessagesViewController/JSQMessagesViewController.h>

@interface ChatViewController : JSQMessagesViewController <NSFetchedResultsControllerDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
