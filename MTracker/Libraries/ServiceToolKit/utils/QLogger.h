//==============================================================================
//	Created on 2007-12-12
//==============================================================================
//	$Id: Logger.h 558 2013-04-03 10:04:40Z shawn.qianx $
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
#ifndef LOGGER_H_
#define LOGGER_H_

#import <Foundation/Foundation.h>

typedef enum _LOG_LEVEL{
	LOG_DEBUG = 0,
	LOG_INFO,
	LOG_WARN,
	LOG_ERROR,
	LOG_FATAL
}LogLevel;

void _simpleLog(const char* file, int line, LogLevel logLevel, NSString* format, ...);
#ifdef __FILE__
#if DEBUG
#define DBG(x,...) _simpleLog(__FILE__,__LINE__,LOG_DEBUG,x,##__VA_ARGS__)
#else
#define DBG(x,...)
#endif
#define LOG(x,...) _simpleLog(__FILE__,__LINE__,LOG_INFO,x,##__VA_ARGS__)
#define INFO(x,...) _simpleLog(__FILE__,__LINE__,LOG_INFO,x,##__VA_ARGS__)
#define WARN(x,...) _simpleLog(__FILE__,__LINE__,LOG_WARN,x,##__VA_ARGS__)
#define ERROR(x,...) _simpleLog(__FILE__,__LINE__,LOG_ERROR,x,##__VA_ARGS__)
#define FATAL(x,...) _simpleLog(__FILE__,__LINE__,LOG_FATAL,x,##__VA_ARGS__)
#else
#if DEBUG
#define DBG(x,...) _simpleLog(nil,0,LOG_DEBUG,x,##__VA_ARGS__)
#else
#define DBG(x,...)
#endif
#define LOG(x,...) _simpleLog(nil,0,LOG_INFO,x,##__VA_ARGS__)
#define INFO(x,...) _simpleLog(nil,0,LOG_INFO,x,##__VA_ARGS__)
#define WARN(x,...) _simpleLog(nil,0,LOG_WARN,x,##__VA_ARGS__)
#define ERROR(x,...) _simpleLog(nil,0,LOG_ERROR,x,##__VA_ARGS__)
#define FATAL(x,...) _simpleLog(nil,0,LOG_FATAL,x,##__VA_ARGS__)
#endif
#endif /*LOGGER_H_*/

