/************************************************************
 *  * Hyphenate CONFIDENTIAL
 * __________________
 * Copyright (C) 2016 Hyphenate Technologies. All rights reserved.
 *
 * NOTICE: All information contained herein is, and remains
 * the property of Hyphenate Technologies.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from Hyphenate Technologies.
 */

#import <UIKit/UIKit.h>

@interface UserProfileViewController : UITableViewController

@property (strong, nonatomic, readonly) NSString *username;

- (instancetype)initWithUsername:(NSString *)username;

@end
