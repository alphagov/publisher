class NullTimestamp
  def to_s
    "never"
  end

  def strftime(*_anything)
    "never"
  end
end
