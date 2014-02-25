Timely Reports
==============

Create time-based reports about your database records. e.g. # of records per day, month or year.

Requires Rails >= 3.2 and Ruby >= 1.9.3.


Excel Support
---

Timely can export reports to Excel, but this is disabled by default to avoid including the (somewhat finicky) gem dependencies. To use this feature, install the `ruby-ole` and `spreadsheet` gems and `require 'spreadsheet'` before requiring Timely.