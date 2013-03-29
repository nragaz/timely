require 'active_support/dependencies'

module Timely
  autoload :Cell,               'timely/cell'
  autoload :Column,             'timely/column'
  autoload :ConfigurationError, 'timely/configuration_error'
  autoload :Formatter,          'timely/formatter'
  autoload :Report,             'timely/report'
  autoload :Row,                'timely/row'

  module Formats
    autoload :Excel,            'timely/formats/excel'
    autoload :Hash,             'timely/formats/hash'
    autoload :Json,             'timely/formats/json'
  end

  module Rows
    autoload :Average,                 'timely/rows/average'
    autoload :AverageDaysBetween,      'timely/rows/average_days_between'
    autoload :AverageHoursBetween,     'timely/rows/average_hours_between'
    autoload :AverageWeekHoursBetween, 'timely/rows/average_week_hours_between'
    autoload :Count,                   'timely/rows/count'
    autoload :Present,                 'timely/rows/present'
    autoload :StandardDeviation,       'timely/rows/standard_deviation'
    autoload :Sum,                     'timely/rows/sum'
    autoload :TotalCount,              'timely/rows/total_count'
    autoload :TotalSum,                'timely/rows/total_sum'
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

  def self.periods
    PERIODS
  end

  def self.redis=(server)
    case server
    when String
      if server =~ /redis\:\/\//
        redis = Redis.connect(url: server, thread_safe: true)
      else
        server, namespace = server.split('/', 2)
        host, port, db = server.split(':')
        redis = Redis.new(host: host, port: port,
          thread_safe: true, db: db)
      end
      namespace ||= :timely

      @redis = Redis::Namespace.new(namespace, :redis => redis)
    when Redis::Namespace
      @redis = server
    else
      @redis = Redis::Namespace.new(:timely, :redis => server)
    end
  end

  # Returns the current Redis connection. If none has been created, will
  # create a new one.
  def self.redis
    return @redis if @redis
    self.redis = Redis.respond_to?(:connect) ? Redis.connect : "localhost:6379"
    self.redis
  end

  class Engine < Rails::Engine
  end
end