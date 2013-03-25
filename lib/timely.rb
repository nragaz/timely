require 'active_support/dependencies'

module Timely
  autoload :ConfigurationError, 'timely/configuration_error'
  autoload :Cell,               'timely/cell'
  autoload :Column,             'timely/column'
  autoload :Formatter,          'timely/formatter'
  autoload :Report,             'timely/report'
  autoload :Row,                'timely/row'

  module Formats
    autoload :Excel,            'timely/formats/excel'
    autoload :Hash,             'timely/formats/hash'
    autoload :Json,             'timely/formats/json'
  end

  PERIODS = %w( year quarter month week day hour )

  # Customize the rounding precision
  mattr_accessor :default_precision
  @@default_precision = 2

  # Customize how column headings are formatted
  mattr_accessor :date_formats
  @@date_formats = {
    year: "%Y",
    quarter: "%b %Y",
    month: "%b %Y",
    week: "%-1d %b",
    day: "%-1d %b",
    hour: "%-1I %p (%m/%-1d)"
  }

  # Customize the # of periods shown by default
  mattr_accessor :default_lengths
  @@default_lengths = {
    year: 3,
    quarter: 6,
    month: 6,
    week: 5,
    day: 7,
    hour: 8
  }

  # Provide a Redis connection for caching. If this is not configured,
  # the default Rails' cache will be used instead.
  mattr_accessor :redis
  @@redis = nil

  # Define the separator for turning cache keys into strings
  mattr_accessor :cache_separator
  @@cache_separator = ":"

  # Access the configuration in an initializer like:
  #
  #   Timely.setup do |config|
  #     config.redis = ...
  #   end
  def self.setup
    yield self
  end

  class Engine < Rails::Engine
  end
end