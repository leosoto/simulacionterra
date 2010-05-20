class Numeric
  def seconds_as_minutes_string
    "#{'%02d' % (self / 60)}:#{'%02d' % (self % 60)}"
  end
end
