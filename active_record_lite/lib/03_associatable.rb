require_relative '02_searchable'
require 'active_support/inflector'
# require 'byebug'

# Phase IIIa
class AssocOptions

  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize #returns class name, Human as a constant
  end

  def table_name
    self.model_class.table_name #self.model_class => Human, Human.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
      foreign_key: "#{name}_id".to_sym,
      primary_key: :id,
      class_name: name.to_s.camelcase(:upper)
    }

    defaults.keys.each do |key|
      if options[key].nil?
        self.send("#{key}=", defaults[key])
      else
        self.send("#{key}=", options[key])
      end
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      foreign_key: "#{self_class_name.to_s.underscore}_id".to_sym,
      primary_key: :id,
      class_name: name.to_s.singularize.camelcase(:upper)
    }

    defaults.keys.each do |key|
      if options[key].nil?
        self.send("#{key}=", defaults[key])
      else
        self.send("#{key}=", options[key])
      end
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    #primary - other class's id
    #foreign - in your table
    #class - the class we're joining to

    # Human
    #   .where(id: :foreign_key)
    #   .first

    # options.model_class #=> Human
    #   .where((primary_key = options[:primary_key]): options[:foreign_key])
    #   .first

    options = BelongsToOptions.new(name, options)
    define_method(name) do #name is the method_name of the association e.g. :watchers
      f_key_value = self.send(options.foreign_key)
      options.model_class #=> Human
        .where(options.primary_key => f_key_value).first

      # f_key = self.send(options[:foreign_key])
      # f_key = options[:foreign_key]

      # options.send(:foreign_key) => :house_id
      # self.send(options.foreign_key) => means cat2.send(:house_id) => cat2.house_id => returns the actual value (aka cat2 lives in house 4 so this returns 4 )
    end
  end

  def has_many(name, options = {})
    #primary - my id
    #foreign - in other class's table
    #class - the class we're joining to

    #class Human
    # => has many :cats
    # =>  primary: :id (Human.id)
    # =>  foreign: :human_id/owner_id => self_class_name = my class name
    # =>  class: :Cat => name = other class's name

    #which cats do I own:
    # Cat
    #   .where(cats.owner_id = Human.id) (cats.foreign_key = self.id)

    #name: cats, self_class_name: Owner
    # options = HasManyOptions.new(name, options[:primary_key], options)

    #options = HasManyOptions.new(name, self, options) => (name, self.class, options) => self.class resulted in an error that said no column named class_id
    options = HasManyOptions.new(name, self, options)
    define_method(name) do
      p_key_value = self.id
      options.model_class #=> Cat
        .where(options.foreign_key => p_key_value)

    end

  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
