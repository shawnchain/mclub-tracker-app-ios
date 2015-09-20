//==============================================================================
//	Created on 2007-12-12
//==============================================================================
//	$Id: SCLogger.m 614 2013-04-14 12:04:06Z jiandong.ljd $
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
//
// Part of the codes is credited to Shaun Harrison/mobile chat/twenty08

#import "QLogger.h"
#import "SCLogger.h"
#import <Foundation/Foundation.h>


NSString * const SCLOGGER_VERBOSE_ENABLED = @"sclogger_verbose_enabled";
NSString * const SCLOGGER_FILE_ENABLED = @"sclogger_file_enabled";
@interface SCLogger()
-(void)_setupLogLevelFromUserDefaults;
-(void)_log:(LogLevel) logLevel format:(NSString*)format args:(va_list) args;
@property(nonatomic,strong) NSMutableDictionary *logLevelDict;
@end

static NSString* _formalizeFileName(const char* fileName){
    NSString *s = [[NSString stringWithCString:fileName encoding:NSUTF8StringEncoding] lastPathComponent];
    NSUInteger sLen = s.length;
    if(sLen > 14){
        // use the first 6 char and last 5 char;
        s = [NSString stringWithFormat:@"%@...%@",[s substringWithRange:NSMakeRange(0, 4)],[s substringWithRange:NSMakeRange(sLen - 7, 7)]];
    }
    return s;
}

#pragma mark - bridge method for the logger macros
void _simpleLog(const char* file, int line, LogLevel logLevel, NSString* format, ...){    
    SCLogger *s_logger = [SCLogger sharedLogger];
    LogLevel logThreshold = s_logger.thresholdLevel;
    
	if(logLevel < logThreshold){
		// Don't need log
		return;
	}
    
    // append file:line
	if(file){
        // Get specific log level according to the file name
        for(NSString *s in s_logger.logLevelDict.allKeys){
            NSString *fileName = [[NSString stringWithCString:file encoding:NSUTF8StringEncoding] lastPathComponent];
            if([fileName hasPrefix:s]){
                logThreshold = ((NSNumber*)[s_logger.logLevelDict objectForKey:s]).intValue;
                if(logLevel < logThreshold){
                    return;
                }
            }
        }
        
        format = [NSString stringWithFormat:@"%@:%d - %@",_formalizeFileName(file) , line,format];
	}
        
	va_list args;
	va_start(args,format);
    [s_logger _log:logLevel format:format args:args];
	va_end(args);
}




#pragma mark - SCLogger implementation
@implementation SCLogger

@synthesize logLevelDict = _logLevelDict;
@synthesize thresholdLevel = _thresholdLevel;
@synthesize logFilePath = _logFilePath;

-(void)_setupLogLevelFromUserDefaults{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if([defaults boolForKey:SCLOGGER_VERBOSE_ENABLED]){
        _thresholdLevel = LOG_DEBUG;
    }else{
#if DEBUG
        _thresholdLevel = LOG_DEBUG;
#else
        _thresholdLevel = LOG_WARN;
#endif
    }
    _enableFileOutput = [defaults boolForKey:SCLOGGER_FILE_ENABLED];
    if(_enableFileOutput && !_logFilePath){
        NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        _logFilePath = [[docPath stringByAppendingPathComponent:@"debug.log"] retain];
    }
}

-(void)userDefaultsChanged:(NSNotification*)notify{
    [self _setupLogLevelFromUserDefaults];
#if DEBUG
    NSLog(@"UserDefaults changed: %@",notify.object);
#endif
}

static NSString* _logLevelValToStr(LogLevel level){
	switch(level){
		case 	LOG_FATAL:
			return @"F";
		case 	LOG_ERROR:
			return @"E";
		case 	LOG_WARN:
			return @"W";
		case 	LOG_INFO:
			return @"I";
		case 	LOG_DEBUG:
			return @"D";
		default:
			return @"I";// All unknow log levels are treated as INFO
	}
}
static NSString* _formatDate(NSDate* date){
    static NSDateFormatter* formatter = nil;
    if (nil == formatter) {
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = (@"MM/dd HH:mm:ss");
        formatter.locale = [NSLocale currentLocale];
    }
    return [formatter stringFromDate:date];
}

+(SCLogger*)loggerWithFileName:(NSString*)fileName{
    return [self loggerWithFileName:fileName threshold:LOG_INFO];
}

+(SCLogger*)loggerWithFileName:(NSString*)fileName threshold:(LogLevel)level{
    SCLogger *logger = [[SCLogger alloc] init];
    logger.thresholdLevel = level;
    if(fileName){
        NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        logger->_logFilePath = [[docPath stringByAppendingPathComponent:fileName] retain];;
        logger->_enableFileOutput = YES;
    }
    return [logger autorelease];
}

+(SCLogger*)sharedLogger{
    static SCLogger *logger = nil;
    if(logger == nil){
        logger = [[SCLogger alloc]init];
        [logger _setupLogLevelFromUserDefaults];
        //Receive setting changes
        [[NSNotificationCenter defaultCenter] addObserver:logger selector:@selector(userDefaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
    }
    return logger;
}

-(id)init{
    self = [super init];
    if(self){
        self->_enableConsoleOutput = YES;
        _logLevelDict = [[NSMutableDictionary alloc] initWithCapacity:8];
    }
    return self;
}
-(void)dealloc{
    if(_logFilePath){
        [_logFilePath release];
        _logFilePath = nil;
    }
    self.logLevelDict = nil;
    
    [super dealloc];
}

#pragma mark - Log levels
-(void)setLogLevel:(LogLevel)loglevel named:(NSString*)className{
    [_logLevelDict setObject:[NSNumber numberWithInt:loglevel] forKey:className];
}
-(NSDictionary*) logLevelDict{
    return _logLevelDict;
}

-(void)_log:(NSString*)logText{
    // Write to console
    if(_enableConsoleOutput)
        NSLog(@"%@",logText);
    
    // Write to file if configured
    if(_enableFileOutput && _logFilePath){
        FILE *_logFile = fopen([_logFilePath cStringUsingEncoding:NSUTF8StringEncoding],"a");
        if(_logFile){
            fprintf(_logFile,"%s %s\n",[_formatDate([NSDate date]) cStringUsingEncoding:NSUTF8StringEncoding],[logText cStringUsingEncoding:NSUTF8StringEncoding]);
            fclose(_logFile);
        }
    }
}

-(void)_log:(LogLevel) logLevel format:(NSString*)format args:(va_list) args{
    // render the body
	NSString *logBody=[[NSString alloc] initWithFormat:format arguments:args];
    // append level prefix
    NSString *logText = [NSString stringWithFormat:@"[%@] - %@",_logLevelValToStr(logLevel),logBody];
    [self _log:logText];
    [logBody release];
}

-(void)log:(NSString*)format, ...{
    va_list args;
	va_start(args,format);
    NSString *logText = [[NSString alloc] initWithFormat:format arguments:args];
    [self _log:logText];
    [logText release];
	va_end(args);
}

-(void)log:(LogLevel)logLevel format:(NSString*)format, ...{
    if(logLevel < _thresholdLevel){
        return;
    }
    va_list args;
	va_start(args,format);
    [self _log:logLevel format:format args:args];
	va_end(args);
}

-(void)debug:(NSString*)format, ...{
    if(LOG_DEBUG < _thresholdLevel){
        return;
    }
    va_list args;
	va_start(args,format);
    [self _log:LOG_DEBUG format:format args:args];
	va_end(args);
}
-(void)info:(NSString*)format, ...{
    if(LOG_INFO < _thresholdLevel){
        return;
    }
    va_list args;
	va_start(args,format);
    [self _log:LOG_INFO format:format args:args];
	va_end(args);
}
-(void)warn:(NSString*)format, ...{
    if(LOG_WARN < _thresholdLevel){
        return;
    }
    va_list args;
	va_start(args,format);
    [self _log:LOG_WARN format:format args:args];
	va_end(args);
}
-(void)error:(NSString*)format, ...{
    if(LOG_ERROR < _thresholdLevel){
        return;
    }
    va_list args;
	va_start(args,format);
    [self _log:LOG_ERROR format:format args:args];
	va_end(args);
}
-(void)fatal:(NSString*)format, ...{
    if(LOG_FATAL < _thresholdLevel){
        return;
    }
    va_list args;
	va_start(args,format);
    [self _log:LOG_FATAL format:format args:args];
	va_end(args);
}


-(void)clearLogFile{
    if(!_logFilePath){
        return;
    }
    const char* filePath = [_logFilePath cStringUsingEncoding:NSUTF8StringEncoding];
    unlink(filePath);
    FILE *_logFile = fopen(filePath,"w");
    NSString *buffer = @"Log data cleared";
    if(_logFile){
        fprintf(_logFile,"%s %s\n",[_formatDate([NSDate date]) cStringUsingEncoding:NSUTF8StringEncoding],[buffer cStringUsingEncoding:NSUTF8StringEncoding]);
        fflush(_logFile);
        fclose(_logFile);
    }
}
@end