class SQLToolkit::Query

  class Relation < Struct.new(:schema_name, :table_name)
    def to_s
      if schema_name.nil?
        SQLToolkit.safe_identifier(table_name)
      else
        SQLToolkit.safe_identifier(schema_name) + '.' + SQLToolkit.safe_identifier(table_name)
      end
    end
  end

  attr_reader :ast

  def initialize(sql)
    @ast = SQLToolkit.parser.parse(sql) or raise SQLToolkit::ParseError.new("Could not parse SQL query: #{sql}")
  end

  def relations
    find_nodes(ast, SQLToolkit::SQL::TableReference).map { |tr| Relation.new(tr.schema_name, tr.table_name) }.uniq
  end

  def sources
    find_nodes(ast, SQLToolkit::SQL::Source)
  end

  def source_names
    sources.map(&:variable_name).uniq
  end

  def stub(source_name, source_stub)
    stub_sql = source_stub.respond_to?(:sql) ? source_stub.sql : source_stub.to_s
    self.class.new(render_stubbed_sql(ast, source_name.to_s, stub_sql))
  end

  def sql
    ast.input
  end

  protected

  def render_stubbed_sql(ast, source, stubbed_query)
    return ast.text_value if ast.elements.nil?
    return "(#{stubbed_query}) AS #{source}" if ast.respond_to?(:variable_name) && ast.variable_name == source
    ast.elements.map { |a| render_stubbed_sql(a, source, stubbed_query) }.join('')
  end


  def find_nodes(ast, ext_module)
    return [] if ast.elements.nil?
    results = ast.elements.map do |element|
      find_nodes(element, ext_module)
    end.flatten
      
    results.unshift(ast) if ast.extension_modules.include?(ext_module)
    return results
  end
end
