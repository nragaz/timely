# encoding: UTF-8

class Timely::Rows::AverageDaysBetween < Timely::Row
  self.default_options = { transform: :round }

  def avg_days_sql(function_args)
    older, newer = date_column_names(function_args)
    "DATEDIFF(#{tz(newer)}, #{tz(older)})"
  end

  def date_column_names(function_args)
    older = disambiguate_column_name(function_args[0])
    newer = disambiguate_column_name(function_args[1])

    [older, newer]
  end
end