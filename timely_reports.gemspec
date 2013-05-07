Gem::Specification.new do |spec|
  spec.name         = "timely_reports"
  spec.summary      = "Create reports about periods of time in your database."
  spec.description  = "Create reports about periods of time in your database."
  spec.files        = Dir["lib/**/*"]+["MIT-LICENSE", "Rakefile", "README.md"]
  spec.version      = "0.9.3"
  spec.authors      = ["Nick Ragaz"]
  spec.email        = "nick.ragaz@gmail.com"
  spec.homepage     = "http://github.com/nragaz/timely"

  spec.add_dependency "activesupport", "~> 3.2.0"
  spec.add_dependency "activerecord", "~> 3.2.0"
  spec.add_dependency "ruby-ole"
  spec.add_dependency "spreadsheet"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "sqlite3"
end
