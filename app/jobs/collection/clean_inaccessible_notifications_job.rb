class Collection::CleanInaccessibleNotificationsJob < ApplicationJob
  def perform(user, collection)
    collection.clean_inaccessible_notifications_for(user)
  end
end
