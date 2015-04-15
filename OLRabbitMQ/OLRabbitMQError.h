/******************************************************************************
 *
 *  2015 (C) Copyright Open-RnD Sp. z o.o.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 ******************************************************************************/

#import <Foundation/Foundation.h>
#include <amqp.h>

// Domain used by OLRabbitMQError
#define kOLRabbitMQErrorDomain @"OLRabbitMQ.error"

// UserInfo Keys
#define kOLRabbitMQErrorMessage @"OLRabbitMQ.error.message"

// Error Key Status Code
#define kOLRabbitMQErrorStatusCode @"OLRabbitMQ.error.statuscode"

typedef NS_ENUM(NSUInteger, OLRabbitMQErrorCode) {
    OLRabbitMQErrorCodeResponseNormal,
    OLRabbitMQErrorCodeResponseNone,
    OLRabbitMQErrorCodeResponseLibraryException,
    OLRabbitMQErrorCodeResponseServerException,
    OLRabbitMQErrorCodeResponseServerConnectionClose,
    OLRabbitMQErrorCodeResponseServerChannelClose,
    OLRabbitMQErrorCodeResponseUnknown,
};

// OLRabbitMQErrorCC = Error Core Code
typedef NS_ENUM(NSUInteger, OLRabbitMQErrorCC) {
    OLRabbitMQErrorCCConnect,
    OLRabbitMQErrorCCBind,
    OLRabbitMQErrorCCUnbind,
    OLRabbitMQErrorCCConsume,
    OLRabbitMQErrorCCLogin,
    OLRabbitMQErrorCCQueue,
};


@interface OLRabbitMQError : NSError

+ (instancetype)error:(amqp_rpc_reply_t)x;
+ (void)validOLRabbitMQRpcReplayT:(amqp_rpc_reply_t)x success:(void (^)(void))success failure:(void (^)(OLRabbitMQError* connectionError)) failure;

+ (OLRabbitMQError *)errorOnConn:(NSInteger)code;
+ (void)validOLRabbitMQOnConn:(NSInteger)code success:(void (^)(void))success failure:(void (^)(OLRabbitMQError* connectionError)) failure;

@end