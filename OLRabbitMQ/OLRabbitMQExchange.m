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

#import "OLRabbitMQExchange.h"
#import "OLRabbitMQManager.h"
#import "OLRabbitMQSocket.h"

@interface OLRabbitMQExchange() {
    NSString *_exchange;
    NSArray *_keys;
    NSString *_key;
}

@property (nonatomic) OLRabbitMQSocket *socket;

@end

@implementation OLRabbitMQExchange

- (instancetype)initWithSocket:(OLRabbitMQSocket *)aSocket {
    
    if (! (self = [super init])) {
        return nil;
    }
    
    _socket = aSocket;

    return self;
}

- (void)bindExchange:(NSString *)anExchange routingKey:(NSString *)aKey {
    _key = aKey;
    _exchange = anExchange;
    
    [self queueBindWithExchange:_exchange routingKey:_key];
}

- (void)bindExchange:(NSString *)anExchange routingKeys:(NSArray *)aKeys {
    
    _keys = aKeys;
    _exchange = anExchange;
    
    for (NSString *key in _keys) {
        [self queueBindWithExchange:_exchange routingKey:key];
    }
}

- (void)unbindExchange:(NSString *)anExchange routingKey:(NSString *)aKey {
    _key = aKey;
    _exchange = anExchange;
    
    [self queueUnbindWithExchange:_exchange routingKey:_key];
}

- (void)unbindExchange:(NSString *)anExchange routingKeys:(NSArray *)aKeys {
    
    _keys = aKeys;
    _exchange = anExchange;
    
    for (NSString *key in _keys) {
        [self queueUnbindWithExchange:_exchange routingKey:key];
    }
}

- (OLRabbitMQError *)queueBindWithExchange:(NSString *)exchange routingKey:(NSString *)routingKey {
    __block OLRabbitMQError *error;
    amqp_connection_state_t conn = _socket.conn;
    amqp_bytes_t queuename = _socket.queuename;
    
    const char *__exchange = [exchange cStringUsingEncoding:NSUTF8StringEncoding];
    const char *__routingKey = [routingKey cStringUsingEncoding:NSUTF8StringEncoding];
    if (conn) {
        amqp_queue_bind(conn, 1, queuename, amqp_cstring_bytes(__exchange), amqp_cstring_bytes(__routingKey),
                        amqp_empty_table);
    }
    [OLRabbitMQError validOLRabbitMQRpcReplayT:amqp_get_rpc_reply(conn) success:^{
        
        if ([OLRabbitMQManager logEnabled]) {
            NSLog(@"Binding [OK]");
        }
        
    } failure:^(OLRabbitMQError *connectionError) {
        NSString *msgString = [NSString stringWithFormat:@"Error bind with exchange %@, routingKey %@", exchange, routingKey];
        error = [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorDomain code:OLRabbitMQErrorCCBind userInfo:@{kOLRabbitMQErrorMessage : msgString}];
    }];
    
    return error;
}

- (OLRabbitMQError *)queueUnbindWithExchange:(NSString *)exchange routingKey:(NSString *)routingKey  {
    __block OLRabbitMQError *error;
    amqp_connection_state_t conn = _socket.conn;
    amqp_bytes_t queuename = _socket.queuename;
    
    const char *__exchange = [exchange cStringUsingEncoding:NSUTF8StringEncoding];
    const char *__routingKey = [routingKey cStringUsingEncoding:NSUTF8StringEncoding];
    
    amqp_queue_unbind(conn, 1, queuename, amqp_cstring_bytes(__exchange), amqp_cstring_bytes(__routingKey), amqp_empty_table);
    
    [OLRabbitMQError validOLRabbitMQRpcReplayT:amqp_get_rpc_reply(conn) success:^{
        
        if ([OLRabbitMQManager logEnabled]) {
            NSLog(@"OLRabbitMQ unbind queue: %@ routingKey: %@ [OK]", exchange, routingKey);
        }
        
    } failure:^(OLRabbitMQError *connectionError) {
        NSString *msgString = [NSString stringWithFormat:@"Error unbind with exchange %@, routingKey %@", exchange, routingKey];
        error = [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorDomain code:OLRabbitMQErrorCCBind userInfo:@{kOLRabbitMQErrorMessage : msgString}];
    }];
    
    return error;
}

- (OLRabbitMQError *)basicConsume {
    __block OLRabbitMQError *error;
    amqp_connection_state_t conn = _socket.conn;
    amqp_bytes_t queuename = _socket.queuename;
    
    if (_socket) {
        amqp_basic_consume(conn, 1, queuename, amqp_empty_bytes, 0, 1, 0, amqp_empty_table);
        [OLRabbitMQError validOLRabbitMQRpcReplayT:amqp_get_rpc_reply(conn) success:^{
            
            if ([OLRabbitMQManager logEnabled]) {
                NSLog(@"OLRabbitMQ consume [OK]");
            }
            
        } failure:^(OLRabbitMQError *connectionError) {
            error = [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorDomain code:OLRabbitMQErrorCCConnect userInfo:@{kOLRabbitMQErrorMessage : @"Error consume"}];
        }];
    } else {
        error = [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorDomain code:OLRabbitMQErrorCCConnect userInfo:@{kOLRabbitMQErrorMessage : @"Error socket"}];
    }
    return error;
}

- (amqp_bytes_t)amqpBytesTFromString:(NSString *)aString {
    amqp_bytes_t value = { .bytes = (__bridge void *)([aString dataUsingEncoding:NSUTF8StringEncoding]), .len = aString.length };
    return value;
}

@end
