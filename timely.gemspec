Gem::Specification.new do |s|
  s.name = "timely"
  s.summary = "Create reports about periods of time in your database."
  s.description = "Create reports about periods of time in your database."
  s.files = Dir["lib/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.version = "0.9"
  s.authors = ["Nick Ragaz"]
  s.email = "nick.ragaz@gmail.com"
  s.homepage = "http://github.com/nragaz/timely"

  s.add_dependency "activesupport", "~> 3.2.0"
  s.add_dependency "activerecord", "~> 3.2.0"
  s.add_dependency "ruby-ole"
  s.add_dependency "spreadsheet"

  s.add_development_dependency "sqlite3"
end
