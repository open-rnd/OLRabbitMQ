Pod::Spec.new do |s|

  s.name         = "OLRabbitMQ"
  s.version      = "0.2.0"
  s.summary      = "Objective-C wrapper for librabbitmq-c."
  s.homepage     = "https://github.com/open-rnd/OLRabbitMQ"
  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author       = { "Open-RnD" => "info@open-rnd.pl" }
  s.requires_arc = true

  s.ios.platform          = :ios, '7.0'
  s.ios.deployment_target = '7.0'
  s.source       = { :git => "https://github.com/open-rnd/OLRabbitMQ.git", :tag => s.version }
  s.public_header_files = 'OLRabbitMQ/*.h'
  s.source_files = 'OLRabbitMQ/*.{h,m}'

  s.dependency 'librabbitmqc'

end
