require File.expand_path('bulletin', File.dirname(__FILE__)) 
 
Gem::Specification.new do |s|
  s.name        = 'bulletin'
  s.version     = Bulletin::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Hugh Bien']
  s.email       = ['hugh@hughbien.com']
  s.homepage    = 'https://github.com/hughbien/bulletin'
  s.summary     = 'Command line RSS reader with personalized rankings'
  s.description = 'Command line RSS reader which ranks stories according' +
                  ' to your own tastes.'
 
  s.required_rubygems_version = '>= 1.3.6'
  s.add_dependency 'dm-sqlite-adapter'
  s.add_dependency 'data_mapper'
  s.add_development_dependency 'minitest'
 
  s.files        = Dir.glob('*.{rb,.md}') + %w(bulletin)
  s.bindir       = '.'
  s.executables  = ['bulletin']
end
