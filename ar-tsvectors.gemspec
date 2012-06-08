# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require 'ts_vectors/version'

Gem::Specification.new do |s|
  s.name        = "ar-tsvectors"
  s.version      = TsVectors::VERSION
  s.authors     = ["Alexander Staubo"]
  s.email       = ["alex@bengler.no"]
  s.homepage    = ""
  s.summary     = %q{Support for PostgreSQL's ts_vector data type in ActiveRecord}
  s.description = %q{Support for PostgreSQL's ts_vector data type in ActiveRecord. Perfect for indexing tags, arrays etc.}
  
  s.rubyforge_project = "ar-tsvectors"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "activerecord", ">= 3.0"
  s.add_development_dependency "rspec"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "activerecord-postgresql-adapter"
end
