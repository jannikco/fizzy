require_relative "../../config/environment"

CARDS_COUNT = 200

ApplicationRecord.current_tenant = "37signals"
account = Account.sole
user = User.first
Current.session = user.sessions.last
collection = Collection.first

# Doing

CARDS_COUNT.times do |index|
  card = collection.cards.create!(title: "Doing card #{index}", creator: user, status: :published)
  card.engage
end

# Considering

CARDS_COUNT.times do |index|
  card = collection.cards.create!(title: "Considering card #{index}", creator: user, status: :published)
  card.reconsider
end

# Completed

CARDS_COUNT.times do |index|
  card = collection.cards.create!(title: "Popped card #{index}", creator: user, status: :published)
  card.close
end
