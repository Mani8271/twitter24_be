class MigrateSubscriptionPlanFeaturesToKeys < ActiveRecord::Migration[7.1]
  # Maps old display strings → machine-readable keys.
  # nil means the string had no equivalent key (it was a limit description, not a feature toggle).
  DISPLAY_TO_KEY = {
    "Global feeds"                                         => "global_feed",
    "global feed"                                          => "global_feed",
    "global feeds"                                         => "global_feed",
    "Local feeds 2 km (R)"                                 => "local_feed",
    "Local feeds 8 km (R)"                                 => "local_feed",
    "Local feeds 30 km (R)"                                => "local_feed",
    "Job visibility (1-2) km -> upto 5 posts per month"   => "job_posts",
    "Job visibility (1-8) km -> upto 10 posts per month"  => "job_posts",
    "Job visibility (1-30 km) -> unlimited"                => "job_posts",
    "Local feed up to 30 posts monthly"                    => nil,
    "Local feed up to 50 posts monthly"                    => nil,
    "Local feed -> unlimited"                              => nil,
    "post disappear max in 30 days"                        => nil,
    "post disappear max in 50 days"                        => nil,
    "Disappear (no) -> Can Renew"                          => nil,
    "Radius visibility (2 km)"                             => "post_radius",
    "visibility upto (1-8) km"                             => "post_radius",
    "post only on the Radius by the plan"                  => "post_radius",
    "Offers up to (Range) (upto 5) posts monthly"          => "offers",
    "offers up to (20) per month"                          => "offers",
    "Offers -> unlimited"                                  => "offers",
    "Show in search through out the globe"                 => "global_search",
    "post on any location"                                 => "post_anywhere",
    "Free domain and Domain Edit page"                     => "domain_page",
    "up to 20 Domain uploads"                              => "domain_uploads"
  }.freeze

  def up
    SubscriptionPlan.find_each do |plan|
      keys = Array(plan.features).filter_map { |f| DISPLAY_TO_KEY[f] }.uniq
      # Only migrate if still using display strings (idempotent)
      plan.update_columns(features: keys) if keys.any?
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
