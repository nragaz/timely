# encoding: UTF-8

require 'spreadsheet'

class Timely::Formats::Excel < Timely::Formatter
  CELL_FORMATS = {
    title: Spreadsheet::Format.new(bold: true, size: 14),
    headings: Spreadsheet::Format.new(bold: true, size: 10, align: 'right'),
    values: Spreadsheet::Format.new(align: 'right')
  }

  attr_reader :row_idx, :workbook, :worksheet, :path

  def initialize(report, options={})
    super

    @path       = options[:path] || Tempfile.new('timely-excel').path
    @row_idx    = 0
    @workbook   = Spreadsheet::Workbook.new
    @worksheet  = create_worksheet
  end

  def output
    write_title
    write_columns
    write_rows
    write_generated_at
    save_workbook

    path
  end

  private

  def row_idx
    @row_idx
  end

  def increment_row_idx(by=1)
    @row_idx += by
  end

  def create_worksheet
    worksheet = workbook.create_worksheet
    worksheet.name = 'Report'
    worksheet.column(0).width = 24
    worksheet
  end

  def write_title(worksheet)
    worksheet.row(row_idx).default_format = CELL_FORMATS[:titles]
    worksheet.row(row_idx).push report.title
    increment_row_idx

    worksheet.row(row_idx).push "#{report.starts_at.to_s(:long)} - #{report.ends_at.to_s(:long)} (by #{report.period})"
    increment_row_idx 2 # add a blank line
  end

  def write_columns(worksheet)
    worksheet.row(row_idx).default_format = CELL_FORMATS[:headings]
    worksheet.row(row_idx).push ""
    worksheet.row(row_idx).concat report.columns.map(&:title)

    increment_row_idx
  end

  def write_rows(worksheet, row_idx)
    raw = report.raw
    raw.each do |row, cells|
      worksheet.row(row_idx).push   row.title.dup
      worksheet.row(row_idx).concat cells.map(&:value)
      increment_row_idx
    end
  end

  def write_generated_at
    text = "Generated at #{Time.zone.now.to_formatted_s(:rfc822)}"
    worksheet.row(row_idx).push text

    increment_row_idx
  end

  def save_workbook
    workbook.write path
  end
end