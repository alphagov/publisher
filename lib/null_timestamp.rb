class NullTimestamp
  def to_s
    "never"
  end

  def strftime(*anything)
    "never"
  end
end
