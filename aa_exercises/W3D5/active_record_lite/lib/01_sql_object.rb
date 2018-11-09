require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @columns ||= (
      DBConnection.execute2(<<-SQL)
        SELECT
          *
        FROM
          #{self.table_name}
      SQL
    ).first.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |col|
      define_method(col) { attributes[col] }
      define_method("#{col}=") { |val| attributes[col] = val }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= ActiveSupport::Inflector.tableize(self.name)
  end

  def self.all
    data = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    parse_all(data)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    data = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = ?
    SQL

    data.empty? ? nil : parse_all(data).first
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      if self.class.columns.include?(attr_name.to_sym)
        self.send("#{attr_name}=".to_sym, value)
      else
        raise "unknown attribute '#{attr_name}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    cols = self.class.columns.drop(1) # don't need id
    col_names = cols.join(', ')
    question_marks = (['?'] * cols.length).join(', ')

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_values = self.class.columns
      .drop(1)
      .map { |attr_name| "#{attr_name} = ?"}
      .join(', ')

    id = attribute_values.take(1)
    vals = attribute_values.drop(1)

    DBConnection.execute(<<-SQL, *vals, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_values}
      WHERE
        id = ?
    SQL
  end

  def save
    # ...
  end
end
