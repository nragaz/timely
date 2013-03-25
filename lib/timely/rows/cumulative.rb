# encoding: UTF-8

class Timely::Rows::Cumulative < Timely::Row
  def cumulative_base_count
    scope.where("#{date_column_sql_with_timezone} < ?", starts_at).count
  end
end