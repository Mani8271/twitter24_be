module ValidatedMediaUpload
  # Allowed MIME types for different media categories
  ALLOWED_IMAGE_TYPES = %w[
    image/jpeg
    image/png
    image/gif
    image/webp
  ].freeze

  ALLOWED_VIDEO_TYPES = %w[
    video/mp4
    video/quicktime
    video/x-msvideo
  ].freeze

  ALLOWED_MEDIA_TYPES = (ALLOWED_IMAGE_TYPES + ALLOWED_VIDEO_TYPES).freeze

  # File size limits
  MAX_IMAGE_SIZE = 50.megabytes
  MAX_VIDEO_SIZE = 500.megabytes
  MAX_MEDIA_SIZE = 500.megabytes

  # Validate single file upload
  def validate_media_upload(file, media_type = :any)
    raise "File is required" unless file.present?

    case media_type
    when :image
      validate_file_type(file, ALLOWED_IMAGE_TYPES, "image")
      validate_file_size(file, MAX_IMAGE_SIZE, "image")
    when :video
      validate_file_type(file, ALLOWED_VIDEO_TYPES, "video")
      validate_file_size(file, MAX_VIDEO_SIZE, "video")
    when :any
      validate_file_type(file, ALLOWED_MEDIA_TYPES, "media")
      validate_file_size(file, MAX_MEDIA_SIZE, "media")
    else
      raise "Invalid media_type: #{media_type}"
    end

    # Additional security checks
    validate_file_not_dangerous(file)
  end

  # Validate multiple files
  def validate_media_uploads(files, media_type = :any)
    return if files.blank?

    files = Array(files)
    files.each_with_index do |file, index|
      validate_media_upload(file, media_type)
    rescue => e
      raise "File #{index + 1}: #{e.message}"
    end
  end

  private

  def validate_file_type(file, allowed_types, type_label)
    content_type = file.content_type

    unless allowed_types.include?(content_type)
      raise "Invalid #{type_label} file type. Allowed: #{allowed_types.map { |t| t.split('/').last }.join(', ')}"
    end
  end

  def validate_file_size(file, max_size, type_label)
    max_mb = max_size / 1.megabytes

    if file.size > max_size
      raise "#{type_label.capitalize} file too large. Maximum: #{max_mb}MB"
    end
  end

  def validate_file_not_dangerous(file)
    # Check for suspicious file extensions
    dangerous_extensions = %w[exe bat cmd php sh rb py asp aspx jsp cgi pl]
    filename = file.original_filename&.downcase || ""

    dangerous_extensions.each do |ext|
      if filename.ends_with?(".#{ext}")
        raise "Dangerous file type detected"
      end
    end

    # Verify magic bytes match the declared content type
    validate_file_magic_bytes(file)
  end

  def validate_file_magic_bytes(file)
    # Read first 12 bytes to check magic bytes (file signature)
    file_start = file.read(12)
    file.rewind

    return if file_start.blank?

    magic_bytes = file_start.bytes

    case file.content_type
    when /^image\/jpeg/
      # JPEG signature: FF D8 FF
      unless magic_bytes[0] == 0xFF && magic_bytes[1] == 0xD8 && magic_bytes[2] == 0xFF
        raise "Invalid or corrupted JPEG file"
      end
    when /^image\/png/
      # PNG signature: 89 50 4E 47
      unless magic_bytes[0] == 0x89 && magic_bytes[1] == 0x50 && magic_bytes[2] == 0x4E && magic_bytes[3] == 0x47
        raise "Invalid or corrupted PNG file"
      end
    when /^image\/gif/
      # GIF signature: 47 49 46 (GIF87a or GIF89a)
      unless magic_bytes[0] == 0x47 && magic_bytes[1] == 0x49 && magic_bytes[2] == 0x46
        raise "Invalid or corrupted GIF file"
      end
    when /^image\/webp/
      # WEBP signature: RIFF ... WEBP
      unless file_start.start_with?("RIFF") && file_start[8..11] == "WEBP"
        raise "Invalid or corrupted WebP file"
      end
    when /^video\/mp4/
      # MP4 signature: 00 00 00 [18-20] 66 74 79 70 (ftyp box)
      # This is more complex, do basic check
      unless file_start.include?("ftyp") || magic_bytes[4] == 0x66
        Rails.logger.warn "Possible invalid MP4 file uploaded"
      end
    # For other video types, just accept them (magic byte checking is complex)
    end
  end
end
