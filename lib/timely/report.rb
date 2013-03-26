# encoding: UTF-8

class Timely::Report
  ## Class Definition ##

  class_attribute :_row_args, :_row_scopes, instance_writer: false

  ## Default Row Settings ##

  class_attribute :default_key
  self.default_key = :created_at

  class_attribute :default_klass
  self.default_klass = :total_count

  class << self
    # Define the report's rows in a subclass:
    #
    #   row "Stuff", :created_at, :count do
    #     objects.where type: 'Stuff'
    #   end
    #
    # When the report is generated, the block is evaluated
    # in the context of the report, so you can use helper methods
    # in the report to filter your scopes. For example, you may
    # want to have a `user` attribute on the report and scope each
    # row's data to that user's associations.
    def row(title, key=default_key, klass=default_klass, options={}, &scope)
      self._row_args   ||= []
      self._row_scopes ||= []

      klass = symbol_to_row_class klass if klass.is_a?(Symbol)

      self._row_args << [klass, [title, key, options]]
      self._row_scopes << scope
    end

    private

    # :count -> Timely::Rows::Count
    def symbol_to_row_class(sym)
      klass = sym.to_s.camelcase
      Timely::Rows.const_get(klass)
    rescue
      raise Timely::ConfigurationError, "No row class defined for #{klass}"
    end
  end

  ## Instance Definition ##

  attr_accessor :title, :period, :length, :starts_at, :options

  # This can be overridden to set defaults by calling super(default args)
  def initialize(options={})
    options = options.symbolize_keys
    options.reverse_merge! period: :month

    self.period     = options[:period]
    self.length     = options[:length] || default_length
    self.starts_at  = options[:starts_at] || default_starts_at
    self.ends_at    = options[:ends_at] if options.has_key?(:ends_at)
    self.options    = options
  end

  def to_s
    "#<#{self.class.name} title: \"#{title}\", period: #{period}, starts_at: #{starts_at}, length: #{length}>"
  end

  # ensure that period is a valid symbol and not dangerous
  def period=(val)
    if Timely.periods.include?(val.to_s)
      @period = val.to_sym
    else
      raise Timely::ConfigurationError, "period must be in the list: #{Timely.periods.join(", ")} (provided #{val})"
    end
  end

  # ensure that length is an integer
  def length=(val)
    @length = val.to_i
  end

  # round the given time to the beginning of the period in which the
  # provided time falls
  def starts_at=(val)
    raise Timely::ConfigurationError, "period must be set before setting starts_at" unless period

    if val == :hour
      @starts_at = val.change(min: 0, sec: 0)
    else
      @starts_at = val.send("beginning_of_#{period}")
    end
  end

  # recalculate the length so that the report includes the given date
  def ends_at=(val)
    raise Timely::ConfigurationError, "starts_at must be set before setting ends_at" unless starts_at

    duration_in_seconds = val - starts_at
    period_duration = period == :quarter ? 3.months : 1.send(period)

    self.length = (duration_in_seconds.to_f / period_duration).ceil
  end

  # calculate the end time
  def ends_at
    @ends_at ||= begin
      if period == :quarter
        starts_at.advance months: length * 3
      else
        starts_at.advance periods => length
      end
    end
  end

  # return an array of row objects after evaluating each row's scope in the
  # context of self
  def rows
    @rows ||= _row_args.map.with_index do |args, i|
      klass, args = args

      options = args.extract_options!
      proc    = _row_scopes[i]
      scope   = self.instance_eval(&proc)

      klass.new(*args, scope, options)
    end
  end

  # return an array of column objects representing each time segment
  def columns
    @columns ||= (0..(length-1)).map do |inc|
      args = period == :quarter ? { months: inc*3 } : { periods => inc }
      Timely::Column.new period, starts_at.advance(args)
    end
  end

  def title
    @title.is_a?(Symbol) ? I18n.t("timely.reports.#{@title}") : @title
  end

  # override the cache key to include information about any objects that
  # affect the scopes passed to each row, e.g. a user
  def cache_key
    title.parameterize
  end

  # return a hash where each row is a key pointing to an array of cells
  def raw
    @cache ||= Hash[
      rows.map do |row|
        [row, columns.map { |col| Timely::Cell.new(self, col, row) }]
      end
    ]
  end

  # pass in a custom object that responds to `output`
  def to_format(formatter_klass, options={})
    formatter_klass.new(self, options).output
  end

  private

  # handle `to_#{name}` methods by looking up a formatter class defined as
  # Timely::Formats::#{name.camelcase}
  def method_missing(method, *args, &block)
    if method.to_s =~ /\Ato_(.+)\z/
      to_missing_format $1, args[0]
    else
      super
    end
  end

  # find the formatter class under Timely::Formats
  def to_missing_format(formatter_name, options={})
    formatter_klass = Timely::Formats.const_get(formatter_name.camelcase)
    to_format formatter_klass, options
  end

  # :month -> :months, etc.
  def periods
    "#{period}s".to_sym
  end

  def default_length
    Timely.default_lengths[ period ]
  end

  def default_starts_at
    if period == :quarter
      (length * 3 - 3).months.ago.send("beginning_of_#{period}")
    elsif period == :hour
      Time.zone.now.change(mins: 0).advance(hours: -(length-1))
    elsif period == :day
      Time.zone.now.change(hours: 0).advance(days: -(length-1))
    else
      (length - 1).send("#{period}s").ago.send("beginning_of_#{period}")
    end
  end
end