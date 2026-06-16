class CleanupOrphanedMediaJob < ApplicationJob
  queue_as :default

  def perform
    cleanup_orphaned_blobs
  end

  private

  def cleanup_orphaned_blobs
    start_time = Time.current
    Rails.logger.info("CleanupOrphanedMediaJob: Starting cleanup of orphaned blobs")

    # Find all blobs that are NOT referenced by any attachment
    orphaned_blobs = ActiveStorage::Blob.where.not(
      id: ActiveStorage::Attachment.select(:blob_id)
    )

    total_count = 0
    deleted_count = 0
    failed_count = 0
    total_size_bytes = 0

    orphaned_blobs.find_each do |blob|
      begin
        total_size_bytes += (blob.byte_size || 0)
        # Direct deletion from S3 (synchronous)
        blob.purge
        deleted_count += 1

        size_mb = (blob.byte_size.to_f / (1024 * 1024)).round(2)
        Rails.logger.info("CleanupOrphanedMediaJob: Deleted orphaned blob #{blob.id} (#{blob.filename}, #{size_mb} MB)")
      rescue StandardError => e
        failed_count += 1
        Rails.logger.error("CleanupOrphanedMediaJob: Failed to delete blob #{blob.id}: #{e.message}")
      ensure
        total_count += 1
      end
    end

    duration = Time.current - start_time
    total_size_mb = (total_size_bytes.to_f / (1024 * 1024)).round(2)

    # Log summary
    log_message = "CleanupOrphanedMediaJob: Completed in #{duration.round(2)}s. " \
                  "Total: #{total_count}, Deleted: #{deleted_count}, Failed: #{failed_count}, " \
                  "Size: #{total_size_mb} MB"

    if failed_count > 0
      Rails.logger.warn(log_message)
    else
      Rails.logger.info(log_message)
    end

    # Return stats for monitoring
    {
      total_count: total_count,
      deleted_count: deleted_count,
      failed_count: failed_count,
      total_size_bytes: total_size_bytes,
      total_size_mb: total_size_mb,
      duration_seconds: duration.round(2)
    }
  end
end
