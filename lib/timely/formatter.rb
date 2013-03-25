module Timely
  class Formatter
    attr_accessor :report, :options

    def initialize(report, options={})
      self.report = report
      self.options = options
    end
  end
end