Gem::Specification.new do |s|
  s.name = 'activerecord_cloneable'
  s.version = '0.1.2'
  s.summary = "A library to help clone active records - that is, generate active new record objects with the data copied from an existing record."
  s.authors = ["Adam Palmblad"]
  s.email = 'apalmblad@gmail.com'
  s.date = %q{2013-08-16}
  s.description = %q{A tool to help with cloning of active record objects.}
  s.files= ['MIT-LICENSE', 'README', 'Rakefile', 'activerecord_cloneable.gemspec',
      'test/activerecord_cloneable_test.rb', 'test/test_helper.rb',
      'lib/active_record/cloneable.rb']
end
