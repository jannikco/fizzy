require "test_helper"

class AccessTest < ActiveSupport::TestCase
  test "acesssed" do
    freeze_time

    assert_changes -> { accesses(:writebook_kevin).reload.accessed_at }, from: nil, to: Time.current do
      accesses(:writebook_kevin).accessed
    end

    travel 2.minutes

    assert_no_changes -> { accesses(:writebook_kevin).reload.accessed_at } do
      accesses(:writebook_kevin).accessed
    end
  end

  test "notifications are destroyed when access is lost" do
    kevin = users(:kevin)
    collection = collections(:writebook)

    assert kevin.notifications.count > 0

    notifications_to_be_destroyed = kevin.notifications.select do |notification|
      notification.card&.collection == collection
    end
    assert notifications_to_be_destroyed.any?

    kevin_access = accesses(:writebook_kevin)

    perform_enqueued_jobs only: Collection::CleanInaccessibleNotificationsJob do
      kevin_access.destroy
    end

    remaining_notifications = kevin.notifications.reload.select do |notification|
      notification.card&.collection == collection
    end

    assert_empty remaining_notifications
  end
end
