require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    self.model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    self.class_eval do
      define_method(:primary_key) do
        options[:primary_key] || :id
      end

      define_method(:foreign_key) do
        options[:foreign_key] || "#{name}_id".to_sym
      end

      define_method(:class_name) do
        options[:class_name] || "#{name}".camelcase
      end
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    self.class_eval do
      define_method(:primary_key) do
        options[:primary_key] || :id
      end

      define_method(:foreign_key) do
        options[:foreign_key] || "#{self_class_name}_id".downcase.to_sym
      end

      define_method(:class_name) do
        options[:class_name] || "#{name}".camelcase.singularize
      end
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

    define_method(name) do
      parent_class = options.model_class
      primary_key = self.send(options.primary_key)
      foreign_key = self.send(options.foreign_key)

      parent_class.where(primary_key => foreign_key).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)

    define_method("#{name}".pluralize) do
      child_class = options.model_class
      primary_key = self.send(options.primary_key)
      foreign_key = options.foreign_key

      child_class.where(foreign_key => primary_key)
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
  extend Searchable
end
