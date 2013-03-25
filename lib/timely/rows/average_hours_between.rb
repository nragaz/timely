# encoding: UTF-8

class Timely::Rows::AverageHoursBetween < Timely::Row
  self.default_options = { transform: :round }

  def avg_hours_sql(scope, function_args)
    older, newer = date_column_names(function_args)
    "TIMESTAMPDIFF(MINUTE, #{older}, #{newer}) / 60"
  end

  def date_column_names(function_args)
    older = disambiguate_column_name(function_args[0])
    newer = disambiguate_column_name(function_args[1])

    [older, newer]
  end
end