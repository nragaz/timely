# encoding: UTF-8

class Timely::Rows::AverageWeekHoursBetween < Timely::Row
  self.default_options = { transform: :round }

  private

  def raw_value_from(scope)
    scope.average query
  end

  # This is equivalent to the following, with substitutions:
  #
  #  @old := objects.created_at,
  #  @new := objects.completed_at,
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
  def query
    "((TIME_TO_SEC( TIMEDIFF(#{to}, #{from}) ) - ( ( WEEK(#{to}, 2) - ( WEEK(#{from}, 2) - ( ( YEAR(#{to}) - YEAR(#{from}) ) * 52 ) ) ) * 172800 )) + (( TIME_TO_SEC( TIMEDIFF(#{from}, STR_TO_DATE( CONCAT( DATE_FORMAT(#{from}, '%X%V'), ' Saturday'), '%X%V %W %h-%i-%s' ))) > 0) * TIME_TO_SEC( TIMEDIFF(#{from}, STR_TO_DATE( CONCAT(DATE_FORMAT(#{from}, '%X%V'), ' Saturday'), '%X%V %W %h-%i-%s')) )) + ((TIME_TO_SEC( TIMEDIFF(#{to}, STR_TO_DATE( CONCAT(DATE_FORMAT(#{to}, '%X%V'), ' Saturday'), '%X%V %W %h-%i-%s')) ) > 0) * TIME_TO_SEC( TIMEDIFF(#{to}, STR_TO_DATE( CONCAT(DATE_FORMAT(#{to}, '%X%V'), ' Saturday'), '%X%V %W %h-%i-%s')) )) ) / 3600"
  end

  def from
    @from ||= disambiguate_column_name column[:from]
  end

  def to
    @to ||= disambiguate_column_name column[:to]
  end
end