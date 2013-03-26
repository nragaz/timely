# encoding: UTF-8

module Timely
  class Cell
    attr_accessor :report, :row, :column

    def initialize(report, column, row)
      self.report = report
      self.column = column
      self.row    = row
    end

    def to_s
      "#<#{self.class.name} row: \"#{row.title}\", starts_at: #{column.starts_at}, ends_at: #{column.ends_at}>"
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
      cacheable? ? value_with_caching : value_without_caching
    end

    def cacheable?
      row.cacheable? && column.cacheable?
    end

    def cache_key
      [report.cache_key, row.cache_key, column.cache_key].join(cache_sep)
    end

    private

    def value_without_caching
      row.value(column.starts_at, column.ends_at)
    end

    def value_with_caching
      Timely.redis ? value_from_redis : value_from_rails_cache
    end

    def value_from_rails_cache
      Rails.cache.fetch(cache_key) { value_without_caching }
    end

    # retrieve a cached value from a redis hash.
    #
    # hashes are accessed using the report title and row title. values within
    # the hash are keyed using the column's start/end timestamps
    def value_from_redis
      if val = Timely.redis.hget(redis_hash_key, redis_value_key)
        val = val.include?(".") ? val.to_f : val.to_i
      else
        val = value_without_caching
        Timely.redis.hset(redis_hash_key, redis_value_key, val)
      end

      val
    end

    def redis_hash_key
      @redis_hash_key ||= [report.cache_key, row.cache_key].join(cache_sep)
    end

    def redis_value_key
      @redis_value_key ||= column.cache_key
    end

    def cache_sep
      Timely.cache_separator
    end
  end
end