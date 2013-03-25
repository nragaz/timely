# encoding: UTF-8

class Timely::Rows::TotalCount < Timely::Row
  def value(starts_at, ends_at)
    total ends_at
  end

  private

  def raw_value_from(scope)
    scope.count
  end
end