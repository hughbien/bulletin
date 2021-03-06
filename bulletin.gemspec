Gem::Specification.new do |s|
  s.name        = 'bulletin'
  s.version     = '0.0.6'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Hugh Bien']
  s.email       = ['hugh@hughbien.com']
  s.homepage    = 'https://github.com/hughbien/bulletin'
  s.summary     = 'Command line RSS reader'
  s.description = 'Command line RSS reader'
 
  s.required_rubygems_version = '>= 1.3.6'
  s.add_dependency 'dm-sqlite-adapter'
  s.add_dependency 'data_mapper'
  s.add_dependency 'colorize'
  s.add_dependency 'feedzirra'
  s.add_dependency 'nokogiri'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'simplecov'
 
  s.files        = Dir.glob('*.{rb,.md}') + %w(bulletin)
  s.bindir       = '.'
  s.executables  = ['bulletin']
end
