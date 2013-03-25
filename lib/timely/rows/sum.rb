# encoding: UTF-8

class Timely::Rows::Sum < Timely::Row
  self.default_options = { transform: :to_i }

  private

  def raw_value_from(scope)
    column_sql = disambiguate_column_name options[:column]
    scope.sum column_sql
  end
end