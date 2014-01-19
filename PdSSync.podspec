Pod::Spec.new do |s|
  s.name        = 'PdSSync'
  s.version     = '1.0'
  s.authors     = { 'Benoit Pereira da Silva' => 'benoit@pereira-da-silva.com' }
  s.homepage    = 'https://github.com/benoit-pereira-da-silva/PdSSync'
  s.summary     = 'A simple delta synchronizer'
  s.source      = { :git => 'https://github.com/benoit-pereira-da-silva/PdSSync.git'}
  s.license     = { :type => "LGPL", :file => "LICENSE" }

  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.9'
  s.requires_arc = true
  s.source_files =  'PdSSync/*.{h,m}'
  s.public_header_files = 'PdSSync/**/*.h'
end
