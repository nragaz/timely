# encoding: UTF-8

class Timely::Rows::Present < Timely::Row
  private

  def raw_value_from(scope)
    scope.where(*conditions).count
  end

  def conditions
    column_sql = disambiguate_column_name options[:column]
    ["#{column_sql} IS NOT NULL AND #{column_sql} != ?", ""]
  end
end