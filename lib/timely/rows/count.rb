# encoding: UTF-8

class Timely::Rows::Count < Timely::Row
  private

  def raw_value_from(scope)
    scope.count
  end
end