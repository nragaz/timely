# encoding: UTF-8

class Timely::Rows::AverageWeekHoursBetween < Timely::Row
  self.default_options = { transform: :round }

  # This is equivalent to the following, with substitutions:
  #  @new := reports.downloaded_at,
  #  @old := pages.created_at,
  #  @oldWeek := WEEK(@old, 2),
  #  @newWeek := WEEK(@new, 2),
  #  @weekends := @newWeek - @oldWeek,
  #  @weekendSecs := @weekends * 172800,
  #  @oldWeekSaturday := STR_TO_DATE( CONCAT(DATE_FORMAT(@old, '%X%V'), ' Saturday'), '%X%V %W %h-%i-%s'),
  #  @extraFirstWeekSecs := TIME_TO_SEC( TIMEDIFF(@old, @oldWeekSaturday) ),
  #  @extraFirstWeekSecs := (@extraFirstWeekSecs > 0) * @extraFirstWeekSecs,
  #  @newWeekSaturday := STR_TO_DATE( CONCAT(DATE_FORMAT(@new, '%X%V'), ' Saturday'), '%X%V %W %h-%i-%s'),
  #  @extraLastWeekSecs := TIME_TO_SEC( TIMEDIFF(@new, @newWeekSaturday) ),
  #  @extraLastWeekSecs := (@extraLastWeekSecs > 0) * @extraLastWeekSecs,
  #  @totalSecs := TIME_TO_SEC( TIMEDIFF(@new, @old) ),
  #  @totalHours := @totalSecs / 3600 as total_hours,
  #  @avg := (@totalSecs - @weekendSecs + @extraFirstWeekSecs + @extraLastWeekSecs) / 3600 as weekday_hours
  #
  # The algorithm is:
  #
  #   total time between dates - total time on weekends between dates
  #
  # the total weekend time is adjusted to remove any time before or after
  # the dates themselves (e.g. if the first date is *on* a weekend, then
  # the hours between the weekend beginning and the first date should not
  # be counted)
  def avg_week_hours_sql(function_args)
    older, newer = date_column_names(function_args)
    "((TIME_TO_SEC( TIMEDIFF(#{newer}, #{older}) ) - ( ( WEEK(#{newer}, 2) - ( WEEK(#{older}, 2) - ( ( YEAR(#{newer}) - YEAR(#{older}) ) * 52 ) ) ) * 172800 )) + (( TIME_TO_SEC( TIMEDIFF(#{older}, STR_TO_DATE( CONCAT( DATE_FORMAT(#{older}, '%X%V'), ' Saturday'), '%X%V %W %h-%i-%s' ))) > 0) * TIME_TO_SEC( TIMEDIFF(#{older}, STR_TO_DATE( CONCAT(DATE_FORMAT(#{older}, '%X%V'), ' Saturday'), '%X%V %W %h-%i-%s')) )) + ((TIME_TO_SEC( TIMEDIFF(#{newer}, STR_TO_DATE( CONCAT(DATE_FORMAT(#{newer}, '%X%V'), ' Saturday'), '%X%V %W %h-%i-%s')) ) > 0) * TIME_TO_SEC( TIMEDIFF(#{newer}, STR_TO_DATE( CONCAT(DATE_FORMAT(#{newer}, '%X%V'), ' Saturday'), '%X%V %W %h-%i-%s')) )) ) / 3600"
  end

  def date_column_names(function_args)
    older = disambiguate_column_name(function_args[0])
    newer = disambiguate_column_name(function_args[1])

    [older, newer]
  end
end