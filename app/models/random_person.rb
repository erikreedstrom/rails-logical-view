# Provides a struct for holding person attributes.
#
class RandomPerson < ApplicationRecord
  attr_reader :id, :name, :email, :avatar, :spend

  def initialize(id, name, email, avatar, spend)
    @id = id
    @name = name
    @email = email
    @avatar = avatar
    @spend = spend
  end

  def self.all(limit: 50)
    (0..(limit - 1)).map do |_i|
      new(SecureRandom.uuid,
          Faker::Name.name,
          Faker::Internet.email,
          Faker::Avatar.image(nil, '144x144'),
          Faker::Number.normal(100, 15))
    end
  end
end