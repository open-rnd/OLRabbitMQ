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

#import "OLRabbitMQOperation.h"
// Include header from rabbitmq-c
#include <amqp.h>
#include <amqp_tcp_socket.h>

@interface OLRabbitMQOperation()

@property (atomic) BOOL runLoop;

@end

@implementation OLRabbitMQOperation

- (instancetype)initWithSocket:(OLRabbitMQSocket *)aSocket {
    
    if (! (self = [super init])) {
        return nil;
    }
    
    _socket = aSocket;
    return self;
}

- (void)main {
    [self run];
}

- (void)cancel {
    _runLoop = NO;
    [super cancel];
}

- (void)run {
    _runLoop = YES;
    /* OLRabbitMQ timeout to 0, no waitxing at all */
    struct timeval tv = { .tv_sec = 1,
                          .tv_usec = 0 };
    {
        _running = YES;
        while (_runLoop) {
            
            amqp_rpc_reply_t res;
            amqp_envelope_t envelope;
            
            amqp_maybe_release_buffers(_socket.conn);
            res = amqp_consume_message(_socket.conn, &envelope, &tv, 0);
            
            if (AMQP_RESPONSE_NORMAL != res.reply_type) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (_delegate && [_delegate respondsToSelector:@selector(amqpError:)]) {
                        [_delegate amqpError:[NSError errorWithDomain:kOLRabbitMQErrorDomain code:(int)res.reply_type userInfo:nil]];
                    }
                }];
            } else {
                NSString *routingKey = [[NSString alloc] initWithBytes:envelope.routing_key.bytes length:envelope.routing_key.len encoding:NSUTF8StringEncoding];
                NSData *data = [NSData dataWithBytes:envelope.message.body.bytes length:envelope.message.body.len];
                amqp_destroy_envelope(&envelope);
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (_delegate && [_delegate respondsToSelector:@selector(amqpResponse:routingKey:)]) {
                        [_delegate amqpResponse:data routingKey:routingKey];
                    }
                }];
                
            }
            
        }
        _running = NO;
    }
    NSLog(@"OLRabbitMQOperation [stopped]");
}

- (NSString *)name {
    return @"OLRabbitMQOperation";
}

@end
