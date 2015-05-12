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

#import "OLRabbitMQSocket.h"
#include <amqp_tcp_socket.h>
#include <amqp_ssl_socket.h>

@interface OLRabbitMQSocket() {
    amqp_connection_state_t conn;
    amqp_socket_t *socket;
    amqp_bytes_t queuename;
    BOOL ready;
    
    BOOL ssl_enable;
    
    NSString *vhost;
    NSString *login;
    NSString *password;
    
    NSString *ip;
    int port;
    
    NSString *cacertpem;
    NSString *keypem;
    NSString *certpem;
}

@end

@implementation OLRabbitMQSocket

- (instancetype)initWithIp:(NSString *)aIp port:(NSInteger)aPort {
    
    if (!(self = [super init])) {
        return nil;
    }
    
    ip = aIp;
    port = (int)aPort;
    
    return self;
}

- (amqp_connection_state_t)conn {
    return conn;
}

- (amqp_bytes_t)queuename {
    return queuename;
}

- (BOOL)isReady {
    return ready;
}

- (OLRabbitMQError *)openWithoutSSL {
    
    ssl_enable = NO;
    ready = NO;
    conn = amqp_new_connection();
    socket = amqp_tcp_socket_new(conn);
    
    if (!socket) {
        OLRabbitMQError *error = [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorDomain code:OLRabbitMQErrorCCConnect userInfo:@{kOLRabbitMQErrorMessage : @"Error socket"}];
        return error;
    }
    
    char const *hostname = [ip UTF8String];
    
    amqp_socket_open(socket, hostname, port);
    
    if ([OLRabbitMQManager logEnabled]) {
        NSLog(@"OLRabbitMQConnection hostname: %@ port: %i", [NSString stringWithCString:hostname encoding:NSUTF8StringEncoding], port);
    }
    
    return nil;
}

- (OLRabbitMQError *)openWithSSLWithCacert:(NSString *)cacert keypem:(NSString *)key certpem:(NSString *)cert {
    ssl_enable = YES;
    ready = NO;
    
    cacertpem = cacert;
    keypem = key;
    certpem = cert;
    
    conn = amqp_new_connection();
    socket = amqp_ssl_socket_new(conn);
    
    
    if (!socket) {
        NSLog(@"creating SSL/TLS socket");
    }

    int status = 0;
    char const *hostname = [ip UTF8String];

    status = amqp_socket_open(socket, hostname, port);
    
    if (socket != 0) {
        OLRabbitMQError *error = [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorDomain code:OLRabbitMQErrorCCConnect userInfo:@{kOLRabbitMQErrorMessage : @"Creating SSL/TLS socket"}];
        return error;
    }
    
    
    amqp_set_initialize_ssl_library(1);
    status = amqp_ssl_socket_set_cacert(socket, [cacertpem UTF8String]);
    if (status != 0) {
        NSString *statusCode = [[NSString alloc] initWithFormat:@"%i", status];
        return [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorDomain code:OLRabbitMQErrorCCConnect
                                       userInfo:@{kOLRabbitMQErrorMessage : @"Setting CA certificate",
                                                  kOLRabbitMQErrorStatusCode : statusCode}];
    }
    
    status = amqp_ssl_socket_set_key(socket, [certpem UTF8String], [keypem UTF8String]);
    if (status != 0) {
        NSString *statusCode = [[NSString alloc] initWithFormat:@"%i", status];
        return [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorDomain code:OLRabbitMQErrorCCConnect
                                       userInfo:@{kOLRabbitMQErrorMessage : @"Setting Client cert key",
                                                  kOLRabbitMQErrorStatusCode : statusCode}];
    }
    
    amqp_ssl_socket_set_verify(socket, 0);
    status = amqp_socket_open(socket, hostname, port);
    if (status != 0) {
        NSString *statusCode = [[NSString alloc] initWithFormat:@"%i", status];
        return [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorDomain code:OLRabbitMQErrorCCConnect
                                       userInfo:@{kOLRabbitMQErrorMessage : @"Opening SSL/TLS connection",
                                                  kOLRabbitMQErrorStatusCode : statusCode}];
    }
    
    if ([OLRabbitMQManager logEnabled]) {
        NSLog(@"OLRabbitMQConnection hostname: %@ port: %i", [NSString stringWithCString:hostname encoding:NSUTF8StringEncoding], port);
    }
    
    return nil;
}

- (void)loginVhost:(NSString *)aVhost login:(NSString *)aLogin password:(NSString *)aPassword callback:(void (^)(BOOL ready, NSError*error))callback {
    
    vhost = aVhost;
    login = aLogin;
    password = aPassword;
    
    [self loginConnVHost:vhost login:login password:password];
    
    amqp_channel_open(conn, 1);
    [OLRabbitMQError validOLRabbitMQRpcReplayT:amqp_get_rpc_reply(conn) success:^{
        
        if ([OLRabbitMQManager logEnabled]) {
            NSLog(@"OLRabbitMQ opening channel [OK]");
        }
        
        [self declareNameQueue:^(OLRabbitMQError *error, amqp_bytes_t queue) {
            if (error) {
                callback(NO, error);
            }
            
            if (queue.len == 0) {
                OLRabbitMQError *error = [self closeConnection];
                callback(NO, error);
                
            }
            
            queuename = queue;
            ready = YES;
            callback(YES, nil);
        }];
        
    } failure:^(OLRabbitMQError *connectionError) {
        OLRabbitMQError *error = [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorDomain code:OLRabbitMQErrorCCConnect userInfo:@{kOLRabbitMQErrorMessage : @"Error connect"}];
        callback(NO, error);
    }];

}

- (OLRabbitMQError *)loginConnVHost:(NSString *)aVhost login:(NSString *)aLogin password:(NSString *)aPassword {
    const char *_vhost = [aVhost cStringUsingEncoding:NSUTF8StringEncoding];
    const char *_login = [aLogin cStringUsingEncoding:NSUTF8StringEncoding];
    const char *_passowrd = [aPassword cStringUsingEncoding:NSUTF8StringEncoding];
    
    amqp_rpc_reply_t loginRPC = amqp_login(conn, _vhost, 0, 131072, 30, AMQP_SASL_METHOD_PLAIN, _login, _passowrd);
    OLRabbitMQError *errorValid = [OLRabbitMQError error:loginRPC];
    return errorValid;
}


- (void)declareNameQueue:(void(^)(OLRabbitMQError *error, amqp_bytes_t queue))response {
    
    amqp_bytes_t queue = { .len = 0, .bytes = NULL };
    
    [OLRabbitMQError validOLRabbitMQRpcReplayT:amqp_get_rpc_reply(conn) success:^{
        
        if ([OLRabbitMQManager logEnabled]) {
            NSLog(@"OLRabbitMQ declaring queue connect [OK]");
        }
        
    } failure:^(OLRabbitMQError *connectionError) {
        OLRabbitMQError *error = [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorMessage code:OLRabbitMQErrorCCConnect userInfo:@{kOLRabbitMQErrorMessage : @"Error declaring queue connect"}];
        response (error, queue);
        return;
    }];

    
    amqp_queue_declare_ok_t *r = amqp_queue_declare(conn, 1, amqp_empty_bytes, 0, 0, 0, 1,
                                                    amqp_empty_table);
    if (r == NULL) {
        OLRabbitMQError *error = [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorMessage code:OLRabbitMQErrorCCConnect userInfo:@{kOLRabbitMQErrorMessage : @"Error declaring queue not defined"}];
        response (error, queue);
        return;
    }
    
    queue = amqp_bytes_malloc_dup(r->queue);
    if (queue.bytes == NULL) {
        OLRabbitMQError *error = [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorMessage code:OLRabbitMQErrorCCConnect userInfo:@{kOLRabbitMQErrorMessage : @"Error declaring queue, queue is NULL"}];
        response (error, queue);
    }
    
    response(nil, queue);
}

- (OLRabbitMQError *)closeConnection {
    __block OLRabbitMQError *error;
    amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS);
    amqp_rpc_reply_t close_conn = amqp_connection_close(conn, AMQP_REPLY_SUCCESS);
    [OLRabbitMQError validOLRabbitMQRpcReplayT:close_conn success:^{
        
        if ([OLRabbitMQManager logEnabled]) {
            NSLog(@"OLRabbitMQ connection close [OK]");
        }
        
    } failure:^(OLRabbitMQError *connectionError) {
         error = [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorDomain code:OLRabbitMQErrorCCConnect userInfo:@{kOLRabbitMQErrorMessage : @"Error close connection"}];
    }];
    
    if (error) {
        return error;
    }
    
    int statusSocket = amqp_destroy_connection(conn);
    [OLRabbitMQError validOLRabbitMQOnConn:statusSocket success:^{
        
        if ([OLRabbitMQManager logEnabled]) {
            NSLog(@"OLRabbitMQ destory connection [OK]");
        }
        
    } failure:^(OLRabbitMQError *connectionError) {
        error = [OLRabbitMQError errorWithDomain:kOLRabbitMQErrorDomain code:OLRabbitMQErrorCCConnect userInfo:@{kOLRabbitMQErrorMessage : @"Error destroy connection"}];
    }];
    
    if (error) {
        return error;
    }
    
    if ([OLRabbitMQManager logEnabled]) {
        NSLog(@"OLRabbitMQ connection [closed]");
    }
    return nil;
}

@end
