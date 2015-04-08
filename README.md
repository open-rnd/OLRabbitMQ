### OLRabbitMQ

Objective-C wrapper for rabbitmq-c.

### Installation

* Xcode Subproject
* Cocoapods

#### Requirements

* linked librabbitmq from folder rabbitmq-c (currently version 0.6.1 for all architectures armv7, arm64, x86_64 and i386)

#### Podfile

```ruby
platform :ios, '7.0'
pod "OLRabbitMQ", "~> 0.0.1"
```

### Usage

#### Create socket AMQP
```objective-c
OLRabbitMQSocket _socketAMQP = [[OLRabbitMQSocket alloc] initWithIp:<address ip> port:<port>];
[_socketAMQP createSocketWithVhost:<vhost> login:<login> password:<password> callback:^(BOOL ready, NSError *error) {
	// your implementation...
}];
```

#### Bind to Exchange
```objective-c
OLRabbitMQExchange *exchange = [[OLRabbitMQExchange alloc] initWithSocket:<OLRabbitMQSocket instance>];
[exchange bindExchange:<exchange string name> routingKey:<exchange routing key string>];
```

#### Unbind to Exchange
```objective-c
OLRabbitMQExchange *exchange = [[OLRabbitMQExchange alloc] initWithSocket:<OLRabbitMQSocket instance>];
[exchange unbindExchange:<exchange string name> routingKey:<exchange routing key string>];
```

#### Consume
```objective-c
[exchange basicConsume];
```

#### Response Operation Queue
``` objective-c
OLRabbitMQOperation *operation = [[OLRabbitMQOperation alloc] initWithSocket:<OLRabbitMQSocket instance>];
operation.delegate = self;
[[NSOperationQueue new] addOperation:operation];
```

#### Delegate Operation Queue
```objective-c
- (void)amqpResponse:(NSData *)data routingKey:(NSString *)routingKey;
```

### Warning

Please remember you cannot share a socket 'OLRabbitMQSocket'. The OLRabbitMQ use librabbitmq-c. The librabbitmq library is built with event-driven, single-threaded applications.

### Features
- [ ] librabbitmq-c with SSL

### License

2015 (C) Copyright Open-RnD Sp. z o.o.

Licensed under the Apache License, Version 2.0 (the "License");<br />
you may not use this file except in compliance with the License.<br />
You may obtain a copy of the License at<br />

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software<br />
distributed under the License is distributed on an "AS IS" BASIS,<br />
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.<br />
See the License for the specific language governing permissions and<br />
limitations under the License.
