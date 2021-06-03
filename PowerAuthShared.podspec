Pod::Spec.new do |s|
    # General information
    s.name              = 'PowerAuthShared'
    s.version           = '0.0.1'
    s.summary           = 'Shared swift classes for PowerAuth client SDK'
    s.homepage          = 'https://github.com/wultra/powerauth-apple-shared'
    s.social_media_url  = 'https://twitter.com/wultra'
    s.documentation_url = 'https://github.com/wultra/powerauth-apple-shared/blob/develop/docs/Readme.md'
    s.author            = { 
        'Wultra s.r.o.' => 'support@wultra.com'
    }
    s.license = { 
        :type => 'Apache License, Version 2.0', 
        :file => 'LICENSE' 
    }    
    # Repository
    s.source = { 
        :git => 'https://github.com/wultra/powerauth-apple-shared.git',
        :tag => "#{s.version}"
    }
    
    # Deployment targets
    s.swift_version = '5.3'
    s.ios.deployment_target  = '9.0'
    s.tvos.deployment_target = '9.0'
    s.watchos.deployment_target = '2.0'
    s.osx.deployment_target = '10.15'
    
    # Sources
    s.source_files          = 'Sources/PowerAuthShared/**/*.swift'
    
    # Tests
    #s.test_spec do |ts|
    #  ts.source_files = 'Tests/PowerAuthShared/**/*.swift'
    #end
end