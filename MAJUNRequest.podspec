Pod::Spec.new do |s|


  s.name         = "MAJUNRequest"
  s.version      = "0.0.1"
  s.summary      = "networking"


  s.homepage     = "https://github.com/didiaogithub/MAJUNRequest.git"

  s.license      = { :type => "MIT", :file => "LICENSE" }


  s.author             = { "majun" => "1078231019@qq.com" }

  s.platform     = :ios, "7.0"

  s.source       = { :git => "https://github.com/didiaogithub/MAJUNRequest.git", :tag => "#{s.version}" }

  s.source_files  = "MAJUNRequest", "MAJUNRequest/*.{h,m}"


  s.requires_arc = true


end