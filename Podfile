# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'SwiftAPIBuilder' do
  use_frameworks!
  pod 'SwiftyJSON'
end

target 'SwiftAPITest' do
    use_frameworks!
    pod 'Alamofire'
    pod 'SwiftyJSON'
    pod 'ObjectMapper'
    pod 'AlamofireObjectMapper'
    pod 'Quick'
    pod 'Nimble'
    pod 'RxSwift',    '~> 3.0.0-beta.1'
    pod 'RxCocoa',    '~> 3.0.0-beta.1'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end
