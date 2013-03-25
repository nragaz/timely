# encoding: UTF-8

class Timely::Rows::Present < Timely::Row
  def present_conditions(column)
    column_sql = disambiguate_column_name column
    ["#{column_sql} IS NOT NULL AND #{column_sql} != ?", ""]
  end
end