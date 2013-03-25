# encoding: UTF-8

class Timely::Rows::AverageDaysBetween < Timely::Row
  self.default_options = { transform: :round }

  private

  def raw_value_from(scope)
    scope.average query
  end

  def query
    "DATEDIFF(#{to}, #{from})"
  end

  def from
    @from ||= disambiguate_column_name column[:from]
  end

  def to
    @to ||= disambiguate_column_name column[:to]
  end
end