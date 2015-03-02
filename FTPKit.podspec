
Pod::Spec.new do |s|
  s.name             = "FTPKit"
  s.version          = "1.3.1"
  s.summary          = "An Objective-C lib that provides client side facilities for FTP."
  s.description      = <<-DESC
                        FTPKit is an Objective-C library providing facilities implementing the client side of the File Transfer Protocol (FTP).
                        This lib is based off or inspired by the BlackRaccoon, WhiteReaccoon and Apple's SimpleFTP example. It utilizes the ftplib library, developed by Thomas Pfau, for most of the remote actions.
                       DESC
  s.homepage         = "https://github.com/PeqNP/FTPKit"
  s.license          = 'MIT'
  s.author           = { "Eric Chamberlain" => "eric.chamberlain@hotmail.com" }
  s.source           = { :git => "https://github.com/PeqNP/FTPKit.git", :tag => "v1.3.1" }

  s.requires_arc = true
  s.ios.deployment_target = "6.0"
  s.osx.deployment_target = "10.8"

  s.source_files = 'FTPKit/**/*', 'Libraries/include/ftplib/src/ftplib.{c,h}'

  s.public_header_files = 'FTPKit/**/*.h'
  s.private_header_files = 'FTPKit/Protected/*.h'
  s.prefix_header_contents = <<-PCH
                             #ifdef __OBJC__
                             #import <Foundation/Foundation.h>
                             #endif
                             PCH

end
