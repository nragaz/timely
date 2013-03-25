# encoding: UTF-8

class Timely::Rows::StandardDeviation < Timely::Row
  self.default_options = { transform: :round }

  def stddev_sql(function_args)
    "STDDEV(#{function_args.first}) as sd_val, #{group_column_sql} as sd_group_key"
  end
end