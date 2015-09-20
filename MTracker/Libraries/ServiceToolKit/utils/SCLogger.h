//==============================================================================
//	Created on 2007-12-12
//==============================================================================
//	$Id: SCLogger.h 605 2013-04-11 14:38:20Z shawn.qianx $
//==============================================================================
//	Copyright (C) <2007>  Shawn Qian(shawn.chain@gmail.com)
//
//	This file is part of iSMS. http://code.google.com/p/weisms/
//
//  iSMS is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  iSMS is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with iSMS.  If not, see <http://www.gnu.org/licenses/>.
//==============================================================================

#import "QLogger.h"

/*
 * SCLogger Class
 */
@interface SCLogger : NSObject
@property(nonatomic,assign) LogLevel thresholdLevel;
@property(nonatomic,readonly)NSString *logFilePath;
@property(nonatomic,assign) BOOL enableConsoleOutput;
@property(nonatomic,assign) BOOL enableFileOutput;

/*
 * Create logger with file name and log level
 */
+(SCLogger*)loggerWithFileName:(NSString*)fileName threshold:(LogLevel)level;

/*
 * Create logger with log file name
 */
+(SCLogger*)loggerWithFileName:(NSString*)fileName;

/*
 * Get shared logger instance
 */
+(SCLogger*)sharedLogger;

-(void)setLogLevel:(LogLevel)loglevel named:(NSString*)className;

/*
 * Main log method
 */
-(void)log:(NSString*)format, ...;

-(void)log:(LogLevel)logLevel format:(NSString*)format, ...;
-(void)debug:(NSString*)format, ...;
-(void)info:(NSString*)format, ...;
-(void)warn:(NSString*)format, ...;
-(void)error:(NSString*)format, ...;
-(void)fatal:(NSString*)format, ...;
/*
 * Clear log file
 */
-(void)clearLogFile;
@end

extern NSString * const SCLOGGER_VERBOSE_ENABLED;
extern NSString * const SCLOGGER_FILE_ENABLED;
