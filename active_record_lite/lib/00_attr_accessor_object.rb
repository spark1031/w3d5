class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      define_method(name) do
        instance_variable_get("@#{name}")
      end

      define_method("#{name}=") do |value|
        instance_variable_set("@#{name}", value)
      end
    end
  end

  # my_attr_accessor(:cards)
  # my_attr_accessor(:name)
  #
  # def cards
  #   @cards
  # end
  #
  # def cards=(value)
  #   @cards = value
  # end
end


# class Player < AttrAccessorObject
#   my_attr_accessor :name, :cards
#
#   def initialize(name, cards)
#     @name = name
#     @cards = cards
#   end
#
#
#   def name
#     @name
#   end
#
#   def name=(value)
#     @name = value
#   end
# end

# player = Player.new('Sue', [adlfjdkjfs])
# player.cards`
