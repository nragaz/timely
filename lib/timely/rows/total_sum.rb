# encoding: UTF-8

class Timely::Rows::TotalSum < Timely::Row
  self.default_options = { transform: :to_i }

  def value(starts_at, ends_at)
    total ends_at
  end

  private

  def raw_value_from(scope)
    scope.sum disambiguate_column_name(options[:column])
  end
end