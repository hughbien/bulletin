require File.expand_path('bulletin', File.dirname(__FILE__))

task :default => :test

task :test do
  print `ruby *_test.rb`
end

task :build do
  `gem build bulletin.gemspec`
end

task :clean do
  rm Dir.glob('*.gem')
end

task :push => :build do
  `gem push bulletin-#{Bulletin::VERSION}.gem`
end
