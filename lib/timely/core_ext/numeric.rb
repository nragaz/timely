class Numeric
  def safely_divide(n)
    n == 0 ? 0 : self / n
  end
end