Gem::Specification.new do |s|
  s.name = 'childprocess-server'
  s.version = '0.1.0'
  s.date = Date.civil(2013,3,30)
  s.summary = 'Manage and interact with processes, remotely.'
  s.description = 'Manage and interact with CLI processes, remotely via dRuby.'
  s.authors = ["Wu Jun"]
  s.email = 'quark@zju.edu.cn'
  s.homepage = 'https://github.com/quark-zju/childprocess-server'
  s.require_paths = ['lib']
  s.licenses = ['MIT']
  s.has_rdoc = 'yard'
  s.files = %w(LICENSE README.md Rakefile childprocess-server.gemspec)
  s.files += Dir['{lib,spec}/**/*.rb']
  s.add_dependency 'childprocess', '~> 0.3.9'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'rspec', '~> 2.13'
  s.add_development_dependency 'yard', '~> 0.8'
  s.test_files = Dir['spec/**/*.rb']
end

