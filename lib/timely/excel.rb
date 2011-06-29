# encoding: UTF-8

require 'spreadsheet'

module Timely
  class Excel
    attr_accessor :title, :reports
  
    def initialize(title, reports)
      @title = title
      @reports = *reports
    end
  
    def to_xls(path_or_io=nil)
      path_or_io ||= Tempfile.new('excel-report').path
    
      workbook = Spreadsheet::Workbook.new
      worksheet = workbook.create_worksheet
      worksheet.name = 'Report'

      titles_format = Spreadsheet::Format.new(bold: true, size: 14)
      column_headings_format = Spreadsheet::Format.new(bold: true, size: 10, align: 'right')
      subheads_format = Spreadsheet::Format.new(bold: true)
      values_format = Spreadsheet::Format.new(align: 'right')

      worksheet.column(0).width = 24

      worksheet.row(0).default_format = titles_format
      worksheet.row(0).push title
      worksheet.row(1).push "#{@reports.first.starts_at.to_s(:long)} - #{@reports.first.ends_at.to_s(:long)} (by #{@reports.first.period})"
    
      worksheet.row(3).default_format = column_headings_format
      worksheet.row(3).push ""
      worksheet.row(3).concat @reports.first.columns.values
    
      row_index = 4
      reports.each do |report|
        worksheet.row(row_index).default_format = subheads_format
        worksheet.row(row_index).push report.title
      
        row_index += 1
        report.to_hash.each do |row_title, values|
          unless row_title == "" # headings
            worksheet.row(row_index).push row_title.dup
            worksheet.row(row_index).concat values.values
            row_index += 1
          end
        end
        row_index += 1
      end

      worksheet.row(row_index + 2).push "Report generated at #{Time.zone.now.to_formatted_s(:rfc822)}"
    
      workbook.write path_or_io
    
      path_or_io
    end
  end
end