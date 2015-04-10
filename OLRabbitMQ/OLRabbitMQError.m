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

#import "OLRabbitMQError.h"
#include <amqp_tcp_socket.h>

@implementation OLRabbitMQError

+ (void)validOLRabbitMQRpcReplayT:(amqp_rpc_reply_t)x success:(void (^)(void))success failure:(void (^)(OLRabbitMQError* connectionError)) failure {
    OLRabbitMQError *errorValid = [OLRabbitMQError error:x];
    if (errorValid.code == OLRabbitMQErrorCodeResponseNormal) {
        success();
    } else {
        failure(errorValid);
    }
}

+ (instancetype)error:(amqp_rpc_reply_t)x {
    
    OLRabbitMQError *error;
    switch (x.reply_type) {
        case AMQP_RESPONSE_NORMAL:
            error = [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorDomain code:OLRabbitMQErrorCodeResponseNormal userInfo:@{kOLRabbitMQErrorMessage : @"Normal"}];
            break;
        case AMQP_RESPONSE_NONE:
            error = [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorDomain code:OLRabbitMQErrorCodeResponseNone userInfo:@{kOLRabbitMQErrorMessage : @"missing RPC reply type!"}];
            break;
        case AMQP_RESPONSE_SERVER_EXCEPTION:
            error = [self errorServerException:x];
            break;
        case AMQP_RESPONSE_LIBRARY_EXCEPTION: {
            NSString *errorMsgString = [NSString stringWithFormat:@"%s", amqp_error_string2(x.library_error)];
            error = [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorDomain code:OLRabbitMQErrorCodeResponseLibraryException userInfo:@{kOLRabbitMQErrorMessage : errorMsgString}];
            break;
        }
            
    }
    return error;
}

+ (OLRabbitMQError *)errorServerException:(amqp_rpc_reply_t)x {
    OLRabbitMQError *error;
    switch (x.reply.id) {
        case AMQP_CONNECTION_CLOSE_METHOD:
            error = [self errorConnection:x];
            break;
        case AMQP_CHANNEL_CLOSE_METHOD:
            error = [self errorChannelClose:x];
            break;
        default:
            error = [self errorUnknown:x];
    }
    return error;
}

+ (OLRabbitMQError *)errorConnection:(amqp_rpc_reply_t)x {
    
    amqp_connection_close_t *m = (amqp_connection_close_t *) x.reply.decoded;
    NSString *errorConnectionCloseString = [[NSString alloc] initWithBytes:m->reply_text.bytes length:m->reply_text.len encoding:NSUTF8StringEncoding];
    NSString *errorMsgString = [NSString stringWithFormat:@"%@ %@ ", @"server connection close", errorConnectionCloseString];
    return [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorDomain code:OLRabbitMQErrorCodeResponseServerConnectionClose userInfo:@{kOLRabbitMQErrorMessage : errorMsgString}];
}

+ (OLRabbitMQError *)errorChannelClose:(amqp_rpc_reply_t)x {
    
    amqp_channel_close_t *m = (amqp_channel_close_t *) x.reply.decoded;
    NSString *errorChannelCloseString = [[NSString alloc] initWithBytes:m->reply_text.bytes length:m->reply_text.len encoding:NSUTF8StringEncoding];
    NSString *errorMsgString = [NSString stringWithFormat:@"%@ %@ ", @"server connection close", errorChannelCloseString];
    return [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorDomain code:OLRabbitMQErrorCodeResponseServerChannelClose userInfo:@{kOLRabbitMQErrorMessage : errorMsgString}];
}

+ (OLRabbitMQError *)errorUnknown:(amqp_rpc_reply_t)x {
    
    NSString *errorMsgString = [NSString stringWithFormat:@"unknown server error, method id 0x%08X\n", x.reply.id];
    return [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorDomain code:OLRabbitMQErrorCodeResponseUnknown userInfo:@{kOLRabbitMQErrorMessage : errorMsgString}];
}

+ (OLRabbitMQError *)errorOnConn:(NSInteger)code {
    NSString *msgString = [[NSString alloc] initWithCString:amqp_error_string2((int)code) encoding:NSUTF8StringEncoding];
    if ( !msgString ) {
        return nil;
    }
    return [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorDomain code:(int)code userInfo:@{kOLRabbitMQErrorMessage : msgString}];
}

+ (void)validOLRabbitMQOnConn:(NSInteger)code success:(void (^)(void))success failure:(void (^)(OLRabbitMQError* connectionError)) failure {
    OLRabbitMQError *error;
    if (code < 0) {
        error = [OLRabbitMQError errorOnConn:code];
    }
    
    if (error) {
        failure(error);
    } else {
        success();
    }
}

@end