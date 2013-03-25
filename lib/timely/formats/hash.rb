# encoding: UTF-8

class Timely::Formats::Hash < Timely::Formatter
  # Turn a report into a simple hash keyed off of the row titles
  def output
    {}.tap do |hash|
      raw = report.raw

      # headings
      hash[""] = report.columns.map(&:title)

      # data
      raw.each do |row, cells|
        hash[row.title] = cells.map(&:value)
      end
    end
  end
end