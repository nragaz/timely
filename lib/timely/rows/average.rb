# encoding: UTF-8

class Timely::Rows::Average < Timely::Row
  self.default_options = { transform: :round }

  private

  def raw_value_from(scope)
    scope.average column_sql
  end

  def column_sql
    @column_sql ||= disambiguate_column_name options[:column]
  end
end