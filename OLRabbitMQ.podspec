Pod::Spec.new do |s|

  s.name         = "OLRabbitMQ"
  s.version      = "0.0.1"
  s.summary      = "Objective-C wrapper for librabbitmq-c."
  s.homepage     = "https://github.com/open-rnd/OLRabbitMQ"
  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author       = { "Open-RnD" => "info@open-rnd.pl" }
  s.ios.deployment_target = '7.0'
  s.requires_arc = true

  s.source       = { :git => "https://github.com/open-rnd/OLRabbitMQ.git", :tag => s.version }
  s.public_header_files = 'OLRabbitMQ/*.h'
  s.source_files = 'OLRabbitMQ/OLRabbitMQ.h'
  
  s.preserve_paths = 'rabbitmq-c/include/.*h' 
  s.vendored_libraries = 'rabbitmq-c/rabbitmq.a'
  s.xcconfig  =  { 'LIBRARY_SEARCH_PATHS' => '"$(PODS_ROOT)/OLRabbitMQ/rabbitmq-c"',
                   'HEADER_SEARCH_PATHS' => '"$(PODS_ROOT)/OLRabbitMQ/rabbbitmq-c/include"' } 
  s.libraries = 'rabbitmq'

  s.subspec 'OLRabbitMQ' do |ss|
	ss.source_files = 'OLRabbitMQ/*.{h,m}'
  end

  s.subspec 'rabbitmq-c' do |ss|
 	ss.source_files = 'rabbitmq-c/include/*.h', 'rabbitmq-c/utils.h'
  end
 
end
