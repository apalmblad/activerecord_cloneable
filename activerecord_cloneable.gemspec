Gem::Specification.new do |s|
  s.name = 'activerecord_cloneable'
  s.version = '0.3.2'
  s.summary = "A library to help clone active records - that is, generate active new record objects with the data copied from an existing record."
  s.authors = ["Adam Palmblad"]
  s.email = 'apalmblad@gmail.com'
  s.date = %q{2015-02-11}
  s.licenses = ['MIT']
  s.homepage = 'http://github.com/apalmblad/activerecord_cloneble'
  s.add_dependency( "activerecord", "<5.0")
  s.add_development_dependency "sqlite3", '~> 0'
  s.add_development_dependency "minitest", '~> 5', '> 5'
  s.description = %q{A tool to help with cloning of active record objects.}
  s.files= ['MIT-LICENSE', 'README', 'Rakefile', 'activerecord_cloneable.gemspec',
      'test/activerecord_cloneable_test.rb', 'test/test_helper.rb',
      'lib/active_record/cloneable.rb', 'lib/activerecord_cloneable.rb']
end
