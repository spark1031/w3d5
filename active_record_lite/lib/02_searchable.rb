require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    #returns an instance of this class object that meet the params
    where_line = params.keys.map { |attr| "#{attr} = ?"}.join(" AND ")

    results = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL

    results.map { |object_hash| self.new(object_hash) }
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
