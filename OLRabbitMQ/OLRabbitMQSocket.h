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
#import "OLRabbitMQError.h"
#import "OLRabbitMQManager.h"

#include <amqp.h>

@interface OLRabbitMQSocket : NSObject

- (instancetype)initWithIp:(NSString *)aIp port:(NSInteger)aPort;

- (OLRabbitMQError *)openWithoutSSL;
- (OLRabbitMQError *)openWithSSLWithCacert:(NSString *)cacert keypem:(NSString *)key certpem:(NSString *)cert;

- (void)loginVhost:(NSString *)aVhost login:(NSString *)aLogin password:(NSString *)aPassword callback:(void (^)(BOOL ready, NSError*error))callback;

- (BOOL)isReady;
- (amqp_connection_state_t)conn;
- (amqp_bytes_t)queuename;
- (OLRabbitMQError *)closeConnection;

@end
