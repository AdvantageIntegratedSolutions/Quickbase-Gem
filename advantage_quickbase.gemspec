Gem::Specification.new do |s|
  s.name            = 'advantage_quickbase'
  s.version         = '0.6.1'
  s.date            = '2014-06-04'
  s.version         = '0.9.2'
  s.date            = '2015-03-04'
  s.summary         = 'Quickbase API gem'
  s.description     = 'Fast, concise implementation of select Quickbase API functions'
  s.authors         = ["Ben Roux"]
  s.email           = 'liquid.ise@gmail.com'
  s.homepage        = 'https://github.com/AdvantageIntegratedSolutions/Quickbase-Gem'
  s.license         = 'MIT'

  s.files           = Dir['lib/*.rb']
  s.require_path    = 'lib'

  s.add_runtime_dependency 'nokogiri'
end
