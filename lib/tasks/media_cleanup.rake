namespace :media do
  desc 'Cleanup expired posts and associated media files'
  task cleanup_expired_posts: :environment do
    puts "Starting cleanup of expired posts..."
    CleanupExpiredPostsJob.perform_now
    puts "Finished cleanup of expired posts."
  end

  desc 'Cleanup orphaned media files from ActiveStorage'
  task cleanup_orphaned_media: :environment do
    puts "Starting cleanup of orphaned media..."
    CleanupOrphanedMediaJob.perform_now
    puts "Finished cleanup of orphaned media."
  end

  desc 'Run all media cleanup tasks'
  task cleanup_all: :environment do
    Rake::Task['media:cleanup_expired_posts'].invoke
    Rake::Task['media:cleanup_orphaned_media'].invoke
  end
end
