require_relative 'db_connection'
require 'active_support/inflector'

# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  
  def self.columns
    return @columns if @columns
    cols = DBConnection.execute2(<<-SQL).first
      SELECT *
      FROM #{self.table_name}
      LIMIT 0
    SQL
    cols.map!(&:to_sym)
    @columns = cols
  end

  def self.finalize!
    self.columns.each do |col_name| #why do I need to do self.columns NOT SQLObject.columns?
      define_method(col_name) do
        self.attributes[col_name] #@attributes[col_name]
      end

      define_method("#{col_name}=") do |value|
        self.attributes[col_name] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.name.underscore.pluralize
  end

  def self.all
    #fetches all records from database
    # => use SQL query (use heredoc syntax)
    rows = DBConnection.execute(<<-SQL) # why do we do #{table_name} NOT #{@table_name}? isn't table_name == self.table_name == @table_name?
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      SQL
    parse_all(rows)
  end

  def self.parse_all(results)
    #self => returns Cat or SQLObject
    results.map do |object_attr_hash|
      self.new(object_attr_hash) #why is it self.new NOT self.class.new, I thought self was an instance of a class at this stage?
    end
  end

  def self.find(id)
    row_of_interest = DBConnection.execute(<<-SQL, id)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        #{table_name}.id = ?
    SQL
    return nil if row_of_interest.empty?
    parse_all(row_of_interest).first
  end

  def initialize(params = {})
    #iterate thru params hash
    # => for each attr_name/key: convert to_sym, check if this exists in columns, if not raise error
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      unless self.class.columns.include?(attr_name)
        raise "unknown attribute '#{attr_name}'"
      else
        self.send("#{attr_name}=", value) #this method is established in #finalize!?
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |attr| self.send(attr)}
  end

  def insert
    columns = self.class.columns.drop(1)
    col_names = columns.map(&:to_s).join(", ")
    question_marks = (["?"] * columns.length).join(", ")

    DBConnection.execute(<<-SQL, *self.attribute_values.drop(1))
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    #updates record's attributes
    columns = self.class.columns
    set_line = columns.map { |attr| "#{attr} = ?" }
    set_line = set_line.join(", ")

    DBConnection.execute(<<-SQL, *self.attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        #{self.class.table_name}.id = ?
    SQL
  end

  def save
    if self.id.nil?
      self.insert
    else
      self.update
    end
  end
end
