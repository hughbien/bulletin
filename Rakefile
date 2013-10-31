require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'bulletin'))

task :default => :test

desc 'Run tests'
task :test do
  print `ruby test/*_test.rb`
end

desc 'Generate coverage report'
task :coverage do
  ENV['COVERAGE'] = 'true'
  print `ruby *_test.rb && firefox coverage/index.html`
end

desc 'Build tags'
task :tags do
  `ctags -f .tags *.rb`
end

desc 'Build gem'
task :build do
  `gem build bulletin.gemspec`
end

desc 'Push to rubygems'
task :push => :build do
  `gem push bulletin-#{Bulletin::VERSION}.gem`
end

desc 'Remove generated files'
task :clean do
  rm Dir.glob('*.gem')
  rm_rf 'coverage'
end
