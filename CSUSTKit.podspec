Pod::Spec.new do |s|
  s.name             = 'CSUSTKit'
  s.version          = '1.4.4'
  s.summary          = 'CSUSTKit 为长沙理工大学学生提供的开发套件。'
  s.homepage         = 'https://github.com/CreaMakers/CSUSTKit'
  s.license          = { :type => 'MPL-2.0', :file => 'LICENSE' }
  s.author           = { 'Zachary Liu' => 'personal@zhelearn.com' }

  s.source           = { :git => 'https://github.com/CreaMakers/CSUSTKit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.swift_versions = ['6.0', '5.0']

  s.source_files = 'Sources/**/*.swift'

  s.dependency 'SwiftSoup', '>= 2.8.8'
  s.dependency 'Alamofire', '>= 5.10.2'
  s.dependency 'CryptoSwift', '>= 1.8.4'
end
