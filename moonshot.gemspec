Gem::Specification.new do |s|
  s.name        = 'moonshot'
  s.version     = '0.6.0'
  s.licenses    = ['MIT']
  s.summary     = 'A library for launching services into AWS'
  s.description = 'A library for launching services into AWS.'
  s.authors     = [
    'Cloud Engineering <engineering@acquia.com>'
  ]
  s.email       = 'engineering@acquia.com'
  s.files       = Dir['lib/**/*.rb']
  s.homepage    = 'https://github.com/acquia/moonshot'

  s.add_dependency('aws-sdk', '~> 2.2.0')
  s.add_dependency('colorize')
  s.add_dependency('highline', '~> 1.7.2')
  s.add_dependency('interactive-logger', '~> 0.1.1')
  s.add_dependency('rotp', '~> 2.1.1')
  s.add_dependency('ruby-duration')
  s.add_dependency('thor', '~> 0.19.1')
  s.add_dependency('semantic')
  s.add_dependency('vandamme')

  s.add_development_dependency('rspec')
  s.add_development_dependency('simplecov')
  s.add_development_dependency('fakefs')
end
