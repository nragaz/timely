# encoding: UTF-8

class Timely::Rows::Average < Timely::Row
  self.default_options = { transform: :round }

  private

  def raw_value_from(scope)
    column_sql = disambiguate_column_name options[:column]
    scope.average column_sql
  end
end