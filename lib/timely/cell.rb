# encoding: UTF-8

module Timely
  class Cell
    attr_accessor :report, :row, :column

    def initialize(report, column, row)
      self.report = report
      self.column = column
      self.row    = row
    end

    def column_key
      column.to_i
    end

    def column_title
      column.title
    end

    def row_title
      row.title
    end

    def value
      cacheable? ? value_with_caching : raw_value
    end

    def cacheable?
      row.cacheable? && column.cacheable?
    end

    def cache_key
      [report.cache_key, row.cache_key, column.cache_key]
    end

    private

    def raw_value
      row.value(column.starts_at, column.ends_at)
    end

    def value_with_caching
      if Timely.redis
        value_from_redis
      else
        Rails.cache.fetch(cache_key) { raw_value }
      end
    end

    def value_from_redis
      redis_key = cache_key.join(Timely.cache_separator)

      if val = Timely.redis.get(redis_key)
        val = BigDecimal.new(val)
      else
        val = raw_value
        Timely.redis.set(redis_key, val)
      end

      val
    end
  end
end