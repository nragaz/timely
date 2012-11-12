# encoding: UTF-8

require 'timely/core_ext/hash'
require 'timely/core_ext/numeric'

module Timely
  class Report
    PERIODS = {
      year: 'Year',
      quarter: 'Quarter',
      month: 'Month',
      week: 'Week',
      day: 'Day',
      hour: 'Hour'
    }

    SIMPLE_FUNCTIONS      = [:count, :cumulative]
    ONE_COLUMN_FUNCTIONS  = [:sum, :average, :stddev, :present]
    DATE_FUNCTIONS        = [
      :avg_hours_between, :avg_week_hours_between, :avg_days_between
    ]
    FUNCTIONS = SIMPLE_FUNCTIONS + ONE_COLUMN_FUNCTIONS + DATE_FUNCTIONS

    SUMMARY_FUNCTIONS     = [:sum, :divide, :multiply]

    DEFAULT_LENGTHS = {
      year: 3,
      quarter: 6,
      month: 6,
      week: 5,
      day: 7,
      hour: 8
    }

    DEFAULT_DATE_FORMATS = {
      year: "%Y",
      quarter: "%b %Y",
      month: "%b %Y",
      week: "%-1d %b",
      day: "%-1d %b",
      hour: "%-1I %p (%m/%-1d)"
    }

    attr_accessor :title, :period, :length, :starts_at,
                  :show_totals, :date_format, :filter,
                  :rows

    def self.default_length(period)
      DEFAULT_LENGTHS[period]
    end

    def self.default_start(period, length)
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

    def self.default_date_format(period)
      DEFAULT_DATE_FORMATS[period]
    end

    def self.validate_function(row)
      name, args = Report.function_arguments(row)

      unless FUNCTIONS.include?(name)
        raise "Unrecognized function (try #{FUNCTIONS.join(", ")})"
      end

      if ONE_COLUMN_FUNCTIONS.include?(name)
        raise "#{name} requires one column name" unless args.length == 1
      elsif DATE_FUNCTIONS.include?(name)
        raise "#{name} requires two column names" unless args.length == 2
      end
    end

    def self.validate_summary_function(name)
      unless SUMMARY_FUNCTIONS.include?(name)
        raise "Summary function not recognized (try #{SUMMARY_FUNCTIONS.join(", ")})"
      end
    end


    # This can be overridden to set defaults by calling super(default args)
    def initialize(title, options={}, &block)
      options.to_options!
      options.reject! { |k,v| v.nil? || (v.respond_to?(:empty?) && v.empty?) }

      self.title = title
      self.period = options[:period].try(:intern) || :month
      self.length =
        (options[:length] || Report.default_length(period)).to_i
      self.starts_at =
        options[:starts_at] || Report.default_start(period, length)
      self.ends_at = options[:ends_at] if options.has_key?(:ends_at)
      self.show_totals =
        options.has_key?(:show_totals) ? options[:show_totals] : true
      self.date_format =
        options[:date_format] || Report.default_date_format(period)
      self.filter = options[:filter] || nil

      self.rows = []

      instance_eval(&block)
    end

    def starts_at
      if period == :hour
        @starts_at.change(min: 0, sec: 0)
      else
        @starts_at.send("beginning_of_#{period}")
      end
    end

    def ends_at
      if period == :quarter
        starts_at.advance(months: length*3)
      else
        starts_at.advance(period.to_s.pluralize.to_sym => length)
      end
    end

    def length_in_seconds
      ends_at - starts_at
    end

    # must be set after starts_at
    def ends_at=(ends_at)
      new_length = 0
      periods = period.to_s.pluralize.to_sym

      until self.starts_at + new_length.send(periods) > ends_at
        new_length += 1
      end

      self.length = new_length
    end

    def columns
      columns = {}
      key = period == :quarter ? :months : period.to_s.pluralize.to_sym
      interval = period == :quarter ? 3 : 1

      (0..(length-1)).map { |inc|
        dt = starts_at.advance(key => inc * interval)
        columns[date_group_format(dt)] = dt.strftime(date_format)
      }
      columns[:total] = "Total" if show_totals

      columns
    end

    def headings
      [""] +
      columns.keys +
      (show_totals ? ["Total"] : [])
    end

    def show_totals?
      show_totals
    end

    def row(title, scope, date_column, function, options={})
      row = {
        type: :function,
        title: title,
        scope: scope,
        date_column: date_column,
        function: function,
        options: options
      }

      Report.validate_function(row)
      unless row[:scope].respond_to?(:to_sql) || row[:scope].respond_to?(:call)
        row[:scope] = row[:scope].scoped
      end

      @rows << row

      if row[:options][:percentage_of]
        @rows.last[:options][:hidden] = true
        @rows.last[:title] = "~ #{@rows.last[:title]}"

        summary_row(
          title,
          :divide,
          ["~ #{title}", options[:percentage_of]],
          map: lambda { |v| (v * 100).round(1) }
        )
      end
    end

    # Used to aggregate values from multiple rows. Combine with :hidden option
    # on other rows to only show the summary. Note that the other rows need
    # to be defined first.
    def summary_row(title, function, rows, options={})
      Report.validate_summary_function(function)

      @rows << {
        type: :summary,
        title: title,
        function: function,
        rows: rows,
        options: options
      }
    end

    def to_hash
      @cache ||= {}.tap { |h|
        h[""] = columns
        rows.each { |row| h[row[:title]] = get_values(row, h) }
        rows.each { |row| h.delete(row[:title]) if row[:options][:hidden] }
      }
    end

    def to_a
      keyed_hash = {}
      to_hash.each do |title, values|
        title = "column" if title.blank?

        values.each do |date, val|
          keyed_hash[date] ||= {}
          keyed_hash[date][title] = val
        end
      end

      keyed_hash.values
    end


    private

    def table_row_title(t)
      content_tag(
        :th,
        translate_title(row[0]),
        class: 'timely-report-row-title'
      )
    end

    def table_row_columns(arr)
      arr.map.with_index { |v,i|
        content_tag(
          :td,
          v,
          class: (show_totals && i == arr.size-1) ? "total" : ""
        )
      }
    end

    def translate_title(t)
      t.is_a?(Symbol) ? I18n.t("timely_reports.rows.#{t}") : t
    end

    def get_values(row, all_values)
      start_time = Time.now

      if row[:type] == :summary
        unless (row[:rows] - all_values.keys).empty?
          raise "Calculated rows not present (#{row[:rows].join(", ")} in #{all_values.keys.join(", ")}) - try reordering your report"
        end

        fn =
          row[:function] == :sum ? :+ :
          row[:function] == :divide ? :safely_divide :
          row[:function] == :multiply ? :* :
          nil

        values = {}
        all_values[""].keys.each do |k|
          unless k.empty?
            values[k] = row[:rows].map { |r| all_values[r][k].to_f }.inject(fn)
            # values[k] = values[k].round(2) if values[k].respond_to?(:round)
          end
        end
      else
        function_name, function_args = Report.function_arguments(row)
        scope = row_scope(row)

        case function_name
        when :count
          values = scope.count
        when :cumulative
          values = scope.count
          base = rolling_base(row)
          values.each do |k,v|
            values[k] = v + base
            base += v
          end
        when :present
          values = scope.where(*present(scope, function_args.first)).count
        when :sum
          values = scope.sum(function_args.first)
          values.each { |k,v| values[k] = v.to_i }
        when :average
          values = scope.average(function_args.first)
          values.each { |k,v| values[k] = v.to_f.round(2) }
        when :stddev
          values = scope.select("STDDEV(#{function_args.first}) as sd_val, #{period_group(date_column_sql(row))} as sd_group_key")
          values = Hash[ values.map { |o| [o.sd_group_key, o.sd_val] } ]
          values.each { |k,v| values[k] = v.to_f.round(2) }
        when :avg_hours_between
          values = scope.average(avg_hours(scope, function_args))
          values.each { |k,v| values[k] = v.to_f.round(2) }
        when :avg_week_hours_between
          values = scope.average(avg_week_hours(scope, function_args))
          values.each { |k,v| values[k] = v.to_f.round(2) }
        when :avg_days_between
          values = scope.average(avg_days(scope, function_args))
          values.each { |k,v| values[k] = v.to_f.round(2) }
        end

        # Ensure that a value is present for all columns, and only those columns
        columns.each { |group,heading|
          values[group] ||= 0 unless group == :total
        }
        values.keys.each { |k| values.delete(k) unless columns.include?(k) }

        values = values.sorted_hash

        if show_totals && function_name == :cumulative
          values[:total] = values.values.last
        elsif show_totals && [:count, :present, :sum].include?(function_name)
          values[:total] = values.values.inject(0) { |sum,v| sum += v }
        elsif show_totals && function_name == :average
          values[:total] = scope.
                           except(:group).
                           average(function_args.first).
                           to_f.round(2) || 0
        elsif show_totals && function_name == :stddev
          values[:total] = scope.
                           except(:group).
                           select("STDDEV(#{function_args.first}) as sd_val, #{period_group(date_column_sql(row))} as sd_group_key").
                           map { |r| r.sd_val }.
                           first.
                           to_f.round(2) || 0
        elsif show_totals && function_name == :avg_hours_between
          values[:total] = scope.
                           except(:group).
                           average(avg_hours(scope, function_args)).
                           to_f.round(2) || 0
        elsif show_totals && function_name == :avg_week_hours_between
          values[:total] = scope.
                           except(:group).
                           average(avg_week_hours(scope, function_args)).
                           to_f.round(2) || 0
        elsif show_totals && function_name == :avg_days_between
          values[:total] = scope.
                           except(:group).
                           average(avg_days(scope, function_args)).
                           to_f.round(2) || 0
        end
      end

      values.each { |k,v|
        values[k] = row[:options][:map].call(v)
      } if row[:options][:map]

      Rails.logger.info "[timely] #{Time.now - start_time}s - #{title} - #{row[:title]} (by #{period})"

      values
    end

    def self.function_arguments(row)
      row[:function].is_a?(Hash) ?
        [row[:function].keys.first, [*row[:function].values.first]] :
        [row[:function], []]
    end

    def row_scope(row)
      date_col = date_column_sql(row)
      start_val = date_col =~ /_on\z/ ? starts_at.to_date : starts_at
      end_val = date_col =~ /_on\z/ ? ends_at.to_date : ends_at
      filtered_scope(row).where("#{date_col} >= ? AND #{date_col} < ?", start_val, end_val).group( period_group(date_col) ).reorder( date_col )
    end

    def rolling_base(row)
      filtered_scope(row).where("#{date_column_sql(row)} < ?", starts_at).count
    end

    def filtered_scope(row)
      row[:scope].respond_to?(:call) ?
        row[:scope].call(self.filter) :
        row[:scope]
    end

    def date_column_sql(row)
      row[:date_column].include?(".") ?
        row[:date_column] :
        "#{filtered_scope(row).table_name}.#{row[:date_column]}"
    end

    def period_group(column)
      case period
      when :year
        "DATE_FORMAT(#{tz(column)}, '%Y')"
      when :quarter
        "CONCAT(YEAR(#{tz(column)}), QUARTER(#{tz(column)}))"
      when :month
        "DATE_FORMAT(#{tz(column)}, '%Y%m')"
      when :week
        "CONVERT(YEARWEEK(#{tz(column)}, 3), CHAR)"
      when :day
        "DATE_FORMAT(#{tz(column)}, '%Y%m%d')"
      when :hour
        "DATE_FORMAT(#{tz(column)}, '%Y%m%d%H')"
      end
    end

    def date_group_format(date)
      case period
      when :year
        date.strftime("%Y")
      when :quarter
        date.strftime("%Y")+"#{((date.month-1)/3)+1}"
      when :month
        date.strftime("%Y%m")
      when :week
        date.strftime("%Y%U")
      when :day
        date.strftime("%Y%m%d")
      when :hour
        date.strftime("%Y%m%d%H")
      end
    end

    def tz(column)
      if column.last(2) == "on"
        # it's a date
        column
      else
        # it's a time, so try converting the timezone
        "IFNULL(CONVERT_TZ(#{column}, 'UTC', 'Canada/Eastern'), #{column})"
      end
    end

    def present(scope, column)
      ["#{scope.table_name}.#{column} IS NOT NULL AND #{scope.table_name}.#{column} != ?", ""]
    end

    def date_column_names(scope, function_args)
      newer_date = function_args[1].include?(".") ?
        function_args[1] : "#{scope.table_name}.#{function_args[1]}"
      older_date = function_args[0].include?(".") ?
        function_args[0] : "#{scope.table_name}.#{function_args[0]}"

      [newer_date, older_date]
    end

    def avg_hours(scope, function_args)
      newer_date, older_date = date_column_names(scope, function_args)

      "TIMESTAMPDIFF(MINUTE, #{older_date}, #{newer_date}) / 60"
    end

    # This is equivalent to the following, with substitutions:
    #  @new := reports.downloaded_at,
    #  @old := pages.created_at,
    #  @oldWeek := WEEK(@old, 2),
    #  @newWeek := WEEK(@new, 2),
    #  @weekends := @newWeek - @oldWeek,
    #  @weekendSecs := @weekends * 172800,
    #  @oldWeekSaturday := STR_TO_DATE( CONCAT(DATE_FORMAT(@old, '%X%V'), ' Saturday'), '%X%V %W %h-%i-%s'),
    #  @extraFirstWeekSecs := TIME_TO_SEC( TIMEDIFF(@old, @oldWeekSaturday) ),
    #  @extraFirstWeekSecs := (@extraFirstWeekSecs > 0) * @extraFirstWeekSecs,
    #  @newWeekSaturday := STR_TO_DATE( CONCAT(DATE_FORMAT(@new, '%X%V'), ' Saturday'), '%X%V %W %h-%i-%s'),
    #  @extraLastWeekSecs := TIME_TO_SEC( TIMEDIFF(@new, @newWeekSaturday) ),
    #  @extraLastWeekSecs := (@extraLastWeekSecs > 0) * @extraLastWeekSecs,
    #  @totalSecs := TIME_TO_SEC( TIMEDIFF(@new, @old) ),
    #  @totalHours := @totalSecs / 3600 as total_hours,
    #  @avg := (@totalSecs - @weekendSecs + @extraFirstWeekSecs + @extraLastWeekSecs) / 3600 as weekday_hours
    #
    # The algorithm is:
    #
    #   total time between dates - total time on weekends between dates
    #
    # the total weekend time is adjusted to remove any time before or after
    # the dates themselves (e.g. if the first date is *on* a weekend, then
    # the hours between the weekend beginning and the first date should not
    # be counted)
    def avg_week_hours(scope, function_args)
      newer_date, older_date = date_column_names(scope, function_args)

      "((TIME_TO_SEC( TIMEDIFF(#{newer_date}, #{older_date}) ) - ( ( WEEK(#{newer_date}, 2) - ( WEEK(#{older_date}, 2) - ( ( YEAR(#{newer_date}) - YEAR(#{older_date}) ) * 52 ) ) ) * 172800 )) + (( TIME_TO_SEC( TIMEDIFF(#{older_date}, STR_TO_DATE( CONCAT( DATE_FORMAT(#{older_date}, '%X%V'), ' Saturday'), '%X%V %W %h-%i-%s' ))) > 0) * TIME_TO_SEC( TIMEDIFF(#{older_date}, STR_TO_DATE( CONCAT(DATE_FORMAT(#{older_date}, '%X%V'), ' Saturday'), '%X%V %W %h-%i-%s')) )) + ((TIME_TO_SEC( TIMEDIFF(#{newer_date}, STR_TO_DATE( CONCAT(DATE_FORMAT(#{newer_date}, '%X%V'), ' Saturday'), '%X%V %W %h-%i-%s')) ) > 0) * TIME_TO_SEC( TIMEDIFF(#{newer_date}, STR_TO_DATE( CONCAT(DATE_FORMAT(#{newer_date}, '%X%V'), ' Saturday'), '%X%V %W %h-%i-%s')) )) ) / 3600"
    end

    def avg_days(scope, function_args)
      newer_date, older_date = date_column_names(scope, function_args)

      "DATEDIFF(#{tz(newer_date)}, #{tz(older_date)})"
    end
  end
end