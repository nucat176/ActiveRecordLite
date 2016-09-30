require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    # ...
    return @table if @table
    @table = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    @table = @table[0].map {|column_name| column_name.to_sym}
  end

  def self.finalize!
    columns.each do |column|
      define_method("#{column}") do
        attributes[column]
      end

      define_method("#{column}=") do |value|
        attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    # ...
    @table_name = table_name
  end

  def self.table_name
    # ...
    @table_name ||= "#{self}".tableize

  end

  def self.all
    # ...
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    self.parse_all(results)

  end

  def self.parse_all(results)
    # ...
      results.map {|result| self.new(result)}

  end

  def self.find(id)
    # ...
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = ?
    SQL

    self.parse_all(result)[0]
  end

  def initialize(params = {})
    # ...
    params.each do |key, value|
      unless self.class.columns.include?(key.to_sym)
        raise "unknown attribute '#{key}'"
      else
        self.send("#{key}=", value)
      end
    end


  end

  def attributes
    # ...
    @attributes ||= {}
  end

  def attribute_values
    # ...
    self.class.columns.map {|column| self.send("#{column}")}
  end

  def insert
    # ...
    col_names = self.class.columns.join(",")
    question_marks = (["?"] * self.class.columns.length).join(",")
    insert = DBConnection.execute(<<-SQL, attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    # ...
    set_line = self.class.columns.map{|column| "#{column} = ?"}.join(",")
    updated = DBConnection.execute(<<-SQL, attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = ?
    SQL
  end

  def save
    # ...
    if self.id.nil?
      self.insert
    else
      self.update
    end
  end
end
