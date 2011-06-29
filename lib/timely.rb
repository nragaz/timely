require 'active_support/dependencies'

module Timely
  autoload :Report, 'timely/report'
  autoload :Excel,  'timely/excel'
  
  class Engine < Rails::Engine
  end
end