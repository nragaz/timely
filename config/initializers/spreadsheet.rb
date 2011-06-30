Mime::Type.register "application/vnd.ms-excel", :xls

Spreadsheet.client_encoding = 'UTF-8' if defined? Spreadsheet