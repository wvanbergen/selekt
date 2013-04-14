class SQLToolkit::SourceStub

  attr_reader :fields, :rows

  def initialize(*fields)
    @fields = fields
    @rows = []
  end

  def add_row(row)
    raise SQLToolkit::StubError, "Row should have #{fields.size} values" if fields.size != row.size
    @rows << row
  end

  alias_method :<<, :add_row

  def sql
    first_row_sql = [row_sql_with_names(rows[0])]
    other_row_sql = rows[1..-1].map { |row| row_sql_without_names(row) }
    [first_row_sql].concat(other_row_sql).join("\nUNION ALL\n")
  end

  def size
    @rows.size
  end

  alias_method :length, :size

  protected

  def row_sql_with_names(row)
    'SELECT ' + row.map.with_index do |value, index|
      "#{SQLToolkit.quote(value)} AS #{SQLToolkit.safe_identifier(fields[index].to_s)}"
    end.join(', ')
  end

  def row_sql_without_names(row)
    'SELECT ' + row.map do |value|
      SQLToolkit.quote(value)
    end.join(', ')
  end
end
