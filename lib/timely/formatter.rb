# encoding: UTF-8

class Timely::Formatter
  attr_accessor :report, :options

  def initialize(report, options={})
    self.report = report
    self.options = options
  end

  def to_s
    "#<#{self.class.name} report: \"#{report.title}\">"
  end
end