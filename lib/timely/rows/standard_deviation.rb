# encoding: UTF-8

class Timely::Rows::StandardDeviation < Timely::Row
  self.default_options = { transform: :round }

  private

  def raw_value_from(scope)
    scope.select(query).first.sd_val
  end

  def query
    "STDDEV(#{column}) as sd_val"
  end

  def column
    @column ||= disambiguate_column_name options[:column]
  end
end