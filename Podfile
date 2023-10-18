target 'openred' do
  use_frameworks!
  pod 'Erik'
  pod 'FLAnimatedImage', '~> 1.0'
  pod 'ApphudSDK'
  pod 'Google-Mobile-Ads-SDK'
  pod 'Bugsnag'
  plugin 'cocoapods-bugsnag'
end
  
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end
