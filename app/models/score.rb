class Score < ApplicationRecord
  belongs_to :user
  belongs_to :scoreable, polymorphic: true
end
