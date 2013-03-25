# encoding: UTF-8

module Timely
  class Column
    attr_accessor :period, :starts_at, :options

    def initialize(period, starts_at, options={})
      self.period = period
      self.starts_at = starts_at
      self.ends_at = ends_at
      self.options = options
    end

    # calculate the end time
    def ends_at
      @ends_at ||= begin
        args = period == :quarter ? { months: 3 } : { periods => 1 }
        starts_at.advance args
      end
    end

    # calculate the time between the start and the end. useful as the x value
    # for bar and line graphs
    def midpoint
      @midpoint ||= Time.at((starts_at.to_i + ends_at.to_i) / 2)
    end

    def title
      format_time_for_human
    end

    def to_s
      format_time_for_group
    end

    def to_i
      starts_at.to_i
    end

    def cache_key
      [starts_at.to_i, ends_at.to_i].join(Timely.cache_separator)
    end

    # only cache values when the period is over
    def cacheable?
      ends_at < Time.zone.now
    end

    private

    # :month -> :months, etc.
    def periods
      "#{period}s".to_sym
    end

    def format_time_for_group
      case period
      when :year
        starts_at.strftime("%Y")
      when :quarter
        quarter_number = ((starts_at.month - 1) / 3) + 1
        "#{starts_at.year}#{quarter_number}"
      when :month
        starts_at.strftime("%Y%m")
      when :week
        starts_at.strftime("%Y%U")
      when :day
        starts_at.strftime("%Y%m%d")
      when :hour
        starts_at.strftime("%Y%m%d%H")
      end
    end

    def format_time_for_human
      starts_at.strftime Timely.date_formats[period]
    end
  end
end