# encoding: UTF-8

require 'json'

class Timely::Formats::Json < Timely::Formatter
  def output
    JSON.dump report.to_hash
  end
end