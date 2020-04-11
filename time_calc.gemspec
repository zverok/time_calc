require './lib/time_calc/version'

Gem::Specification.new do |s|
  s.name     = 'time_calc'
  s.version  = TimeCalc::VERSION
  s.authors  = ['Victor Shepelev']
  s.email    = 'zverok.offline@gmail.com'
  s.homepage = 'https://github.com/zverok/time_calc'
  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/zverok/time_calc/issues',
    'changelog_uri' => 'https://github.com/zverok/time_calc/blob/master/Changelog.md',
    'documentation_uri' => 'https://www.rubydoc.info/gems/time_calc/',
    'homepage_uri' => 'https://github.com/zverok/time_calc',
    'source_code_uri' => 'https://github.com/zverok/time_calc'
  }

  s.summary = 'Easy time math'
  s.description = <<-EOF
    TimeCalc is a library for idiomatic time calculations, like "plus N days", "floor to month start",
    "how many hours between those dates", "sequence of months from this to that". It intends to
    be small and easy to remember without any patching of core classes.
  EOF
  s.licenses = ['MIT']

  s.required_ruby_version = '>= 2.3.0'

  s.files = `git ls-files lib LICENSE.txt *.md`.split($RS)
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'backports', '>= 3.17.0'

  s.add_development_dependency 'rubocop', '~> 0.77.0'
  s.add_development_dependency 'rubocop-rspec', '~> 1.37.0'

  s.add_development_dependency 'rspec', '>= 3.8'
  s.add_development_dependency 'rspec-its', '~> 1'
  s.add_development_dependency 'saharspec', '>= 0.0.6'
  s.add_development_dependency 'simplecov', '~> 0.9'
  s.add_development_dependency 'tzinfo', '~> 1.1'

  s.add_development_dependency 'activesupport', '>= 5.0' # to test with TimeWithZone

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rubygems-tasks'

  s.add_development_dependency 'yard'
end
