lib_dir = File.join(File.dirname(__FILE__),'lib')
$LOAD_PATH << lib_dir unless $LOAD_PATH.include?(lib_dir)
require 'customer_miner/version'

Gem::Specification.new do |s|
  s.name        = 'customer_miner.gemspec'
  s.version =  CustomerMiner::VERSION
  s.date        = '2017-05-25'
  s.summary     = "Fetch customer data using Clearbit API"
  s.description = "Fetch customer data using Clearbit API"
  s.authors     = ["ocowchun"]
  s.email       = 'ocowchun@gmail.com'
  s.executables = ["cm"]
  s.files = `git ls-files`.split($/)
  s.homepage    =
  'https://github.com/ocowchun/customer_miner'
  s.license       = 'MIT'

  s.add_dependency('thor',["~> 0.19.4"])
end