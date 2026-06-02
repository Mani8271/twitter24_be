class CleanupExpiredPostsJob < ApplicationJob
  queue_as :default

  def perform
    cleanup_expired_global_feeds
    cleanup_expired_jobs
    cleanup_expired_offers
  end

  private

  def cleanup_expired_global_feeds
    expired_feeds = GlobalFeed.where("disappear_after IS NOT NULL")
                              .where("created_at < ?", Time.current - 1.day)
                              .where("created_at + (disappear_after || ' days')::interval <= ?", Time.current)

    expired_feeds.find_each do |feed|
      feed.destroy
      Rails.logger.info("Deleted expired global feed: #{feed.id}")
    end
  end

  def cleanup_expired_jobs
    expired_jobs = Job.where("disappearing_days IS NOT NULL")
                      .where("created_at < ?", Time.current - 1.day)
                      .where("created_at + (disappearing_days || ' days')::interval <= ?", Time.current)

    expired_jobs.find_each do |job|
      job.destroy
      Rails.logger.info("Deleted expired job: #{job.id}")
    end
  end

  def cleanup_expired_offers
    expired_offers = Offer.where("valid_till IS NOT NULL")
                          .where("valid_till <= ?", Time.current)

    expired_offers.find_each do |offer|
      offer.destroy
      Rails.logger.info("Deleted expired offer: #{offer.id}")
    end
  end
end
