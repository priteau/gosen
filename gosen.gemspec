Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.5'

  s.name              = 'gosen'
  s.version           = '0.2.1'
  s.date              = '2011-06-25'
  s.rubyforge_project = 'gosen'

  s.summary     = "A Ruby library for the Grid'5000 RESTful API"
  s.description = "Gosen is a Ruby library providing high-level operations using the Grid'5000 RESTful API, such as Kadeploy deployments."

  s.authors  = ["Pierre Riteau"]
  s.email    = 'priteau@gmail.com'
  s.homepage = 'http://github.com/priteau/gosen'

  s.require_paths = %w[lib]

  s.executables = ["trebuchet"]

  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = %w[README.md LICENSE]

  s.add_dependency('restfully', [">= 0.5.1"])

  s.add_development_dependency('mocha', [">= 0.9.8"])
  s.add_development_dependency('rake')
  s.add_development_dependency('shoulda', [">= 2.10.2"])

  # = MANIFEST =
  s.files = %w[
    LICENSE
    README.md
    Rakefile
    bin/trebuchet
    gosen.gemspec
    lib/gosen.rb
    lib/gosen/deployment.rb
    lib/gosen/deployment_run.rb
    lib/gosen/error.rb
    test/gosen/test_deployment.rb
    test/gosen/test_deployment_run.rb
    test/helper.rb
    test/test_gosen.rb
  ]
  # = MANIFEST =

  ## Test files will be grabbed from the file list. Make sure the path glob
  ## matches what you actually use.
  s.test_files = s.files.select { |path| path =~ /^test\/test_.*\.rb/ }
end
