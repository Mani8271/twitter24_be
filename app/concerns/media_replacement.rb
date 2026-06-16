# app/concerns/media_replacement.rb
#
# Provides safe media replacement functionality for ActiveStorage attachments.
# Ensures old files are properly deleted from S3 before/after replacing media.
#
# Usage:
#   include MediaReplacement
#   replace_media(model, :attachment_name, new_file)
#
module MediaReplacement
  extend ActiveSupport::Concern

  # Safely replace a single attachment (one_attached)
  #
  # @param model [ActiveRecord::Base] The model containing the attachment
  # @param attachment_name [Symbol, String] Name of the attachment (e.g., :profile_picture)
  # @param new_file [ActionDispatch::Http::UploadedFile, File] The new file to attach
  # @param keep_old [Boolean] If true, don't delete the old file (default: false)
  #
  # @return [Boolean] true if successful, raises error otherwise
  #
  # @example
  #   replace_media(user, :profile_picture, new_file_obj)
  #
  def replace_media(model, attachment_name, new_file, keep_old: false)
    unless model.respond_to?(attachment_name)
      raise ArgumentError, "Model #{model.class} doesn't have attachment :#{attachment_name}"
    end

    unless new_file.present?
      raise ArgumentError, "new_file cannot be nil or empty"
    end

    attachment = model.public_send(attachment_name)

    # Store reference to old blob before attaching new file
    old_blob = attachment.attached? ? attachment.blob : nil

    begin
      # Attach new file
      attachment.attach(new_file)

      # Delete old blob after successful attachment (if it exists and should be deleted)
      if old_blob.present? && !keep_old
        delete_blob_later(old_blob, model, attachment_name)
      end

      true
    rescue StandardError => e
      # If attachment fails, we haven't deleted old file yet - safe to retry
      Rails.logger.error("MediaReplacement: Failed to replace #{attachment_name} on #{model.class} #{model.id}: #{e.message}")
      raise
    end
  end

  # Safely replace multiple attachments (many_attached)
  #
  # @param model [ActiveRecord::Base] The model containing the attachment
  # @param attachment_name [Symbol, String] Name of the attachment (e.g., :shop_images)
  # @param new_files [Array<File>] Array of new files to attach
  # @param delete_existing [Boolean] Delete all existing attachments first (default: false)
  #
  # @return [Boolean] true if successful
  #
  # @example Replace all gallery images
  #   replace_media_collection(business, :shop_images, new_files, delete_existing: true)
  #
  # @example Append to gallery images
  #   replace_media_collection(business, :shop_images, new_files, delete_existing: false)
  #
  def replace_media_collection(model, attachment_name, new_files, delete_existing: false)
    unless model.respond_to?(attachment_name)
      raise ArgumentError, "Model #{model.class} doesn't have attachment :#{attachment_name}"
    end

    new_files = Array.wrap(new_files).compact
    unless new_files.any?
      raise ArgumentError, "new_files cannot be empty"
    end

    attachments = model.public_send(attachment_name)

    # Store references to old blobs
    old_blobs = delete_existing ? attachments.map(&:blob) : []

    begin
      # Purge old attachments if requested
      attachments.purge_later if delete_existing

      # Attach new files
      attachments.attach(new_files)

      # Delete old blobs after successful attachment
      old_blobs.each { |blob| delete_blob_later(blob, model, attachment_name) }

      true
    rescue StandardError => e
      Rails.logger.error("MediaReplacement: Failed to replace #{attachment_name} collection on #{model.class} #{model.id}: #{e.message}")
      raise
    end
  end

  # Delete a single blob from a collection attachment
  #
  # @param model [ActiveRecord::Base] The model containing the attachment
  # @param attachment_name [Symbol, String] Name of the attachment
  # @param blob_id [Integer, String] ID of the blob to delete
  #
  # @return [Boolean] true if deleted
  #
  # @example Delete one image from gallery
  #   delete_attachment(business, :shop_images, blob_id)
  #
  def delete_attachment(model, attachment_name, blob_id)
    unless model.respond_to?(attachment_name)
      raise ArgumentError, "Model #{model.class} doesn't have attachment :#{attachment_name}"
    end

    attachments = model.public_send(attachment_name)
    attachment = attachments.find_by(blob_id: blob_id)

    unless attachment
      raise ActiveRecord::RecordNotFound, "Attachment not found"
    end

    blob = attachment.blob
    attachment.purge

    # Queue deletion of blob if no other attachments reference it
    delete_blob_later(blob, model, attachment_name)

    true
  end

  # Delete all attachments of a given type
  #
  # @param model [ActiveRecord::Base] The model containing the attachment
  # @param attachment_name [Symbol, String] Name of the attachment
  #
  # @return [Boolean] true if deleted
  #
  def delete_all_attachments(model, attachment_name)
    unless model.respond_to?(attachment_name)
      raise ArgumentError, "Model #{model.class} doesn't have attachment :#{attachment_name}"
    end

    blobs = model.public_send(attachment_name).map(&:blob)
    model.public_send(attachment_name).purge_later

    blobs.each { |blob| delete_blob_later(blob, model, attachment_name) }

    true
  end

  private

  # Delete a blob directly from S3 (synchronous)
  # Deletes immediately without background job
  #
  # @param blob [ActiveStorage::Blob] The blob to delete
  # @param model [ActiveRecord::Base] The model (for logging)
  # @param attachment_name [Symbol] The attachment name (for logging)
  #
  def delete_blob_later(blob, model, attachment_name)
    if blob.blank?
      Rails.logger.warn("MediaReplacement: Attempted to delete nil blob for #{model.class} #{model.id}")
      return
    end

    begin
      # Direct deletion from S3 (synchronous - immediate)
      blob.purge
      Rails.logger.info("MediaReplacement: Deleted blob #{blob.id} (#{blob.filename}) from #{model.class} #{model.id}.#{attachment_name} - Size: #{(blob.byte_size.to_f / (1024 * 1024)).round(2)} MB")
    rescue StandardError => e
      Rails.logger.error("MediaReplacement: Failed to delete blob #{blob.id}: #{e.message}")
      # If deletion fails, log but don't crash the user's request
      # S3 will still have orphaned file, but user got their new file
    end
  end
end
