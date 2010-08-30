require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "gosen"
    gem.summary = %Q{A Ruby library for the Grid'5000 RESTful API}
    gem.description = %Q{Gosen is a Ruby library providing high-level operations using the Grid'5000 RESTful API, such as Kadeploy deployments.}
    gem.email = "priteau@gmail.com"
    gem.homepage = "http://github.com/priteau/gosen"
    gem.authors = ["Pierre Riteau"]
    gem.add_dependency "restfully", ">= 0.5.1"
    gem.add_development_dependency "mocha", ">= 0.9.8"
    gem.add_development_dependency "shoulda", ">= 2.10.2"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test
