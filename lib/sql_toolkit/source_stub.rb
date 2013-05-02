class SQLToolkit::SourceStub

  attr_reader :fields, :rows

  def initialize(*fields)
    @fields = fields.map { |f| f.to_sym }
    @rows = []
  end

  def add_row(row)
    if row.is_a?(Hash)
      @rows << fields.map { |f| row[f] }
    else
      raise SQLToolkit::StubError, "Row should have #{fields.size} values maximum" if fields.size < row.size
      @rows << fields.map.with_index { |_, i| row[i] }
    end
    return self
  end

  alias_method :<<, :add_row
  alias_method :push, :add_row  

  def add_rows(rows)
    rows.each { |row| add_row(row) }
    return self
  end

  alias_method :concat, :add_rows

  def sql
    first_row_sql = [row_sql_with_names(rows[0])]
    other_row_sql = rows[1..-1].map { |row| row_sql_without_names(row) }
    [first_row_sql].concat(other_row_sql).join("\nUNION ALL\n")
  end

  def size
    @rows.size
  end

  def ==(other)
    return false unless other.is_a?(SQLToolkit::SourceStub)
    fields == other.fields && rows == other.rows
  end

  alias_method :length, :size

  protected

  def row_sql_with_names(row)
    'SELECT ' + fields.map.with_index do |field, index|
      "#{SQLToolkit.quote(row[index])} AS #{SQLToolkit.safe_identifier(field.to_s)}"
    end.join(', ')
  end

  def row_sql_without_names(row)
    'SELECT ' + fields.map.with_index do |field, index|
      SQLToolkit.quote(row[index])
    end.join(', ')
  end
end
