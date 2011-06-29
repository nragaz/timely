class Hash
  def sorted_hash(&block)
    self.class[sort(&block)]   # Hash[ [[key1, value1], [key2, value2]] ]
  end
end