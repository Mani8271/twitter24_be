class CleanupOrphanedMediaJob < ApplicationJob
  queue_as :default

  def perform
    cleanup_orphaned_blobs
  end

  private

  def cleanup_orphaned_blobs
    orphaned_blobs = ActiveStorage::Blob.where.not(
      id: ActiveStorage::Attachment.select(:blob_id)
    )

    count = 0
    orphaned_blobs.find_each do |blob|
      blob.purge_later
      count += 1
    end

    Rails.logger.info("Queued deletion of #{count} orphaned blobs")
  end
end
