# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
AdminUser.find_or_create_by!(email: 'twitter24@gmail.com') do |u|
  u.password = 'Twitter24'
  u.password_confirmation = 'Twitter24'
end

# ─── Subscription Plans ────────────────────────────────────────────────────
plans = [
  {
    plan_type: "Basic",
    position:  0,
    amounts:   "20 per day",
    features: [
      "Global feeds",
      "Local feeds 2 km (R)",
      "Job visibility (1-2) km -> upto 5 posts per month",
      "Local feed up to 30 posts monthly",
      "post disappear max in 30 days",
      "Radius visibility (2 km)",
      "Offers up to (Range) (upto 5) posts monthly"
    ]
  },
  {
    plan_type: "Premium",
    position:  1,
    amounts:   "35 per day",
    features: [
      "global feed",
      "Local feeds 8 km (R)",
      "Job visibility (1-8) km -> upto 10 posts per month",
      "Local feed up to 50 posts monthly",
      "post disappear max in 50 days",
      "visibility upto (1-8) km",
      "offers up to (20) per month",
      "post only on the Radius by the plan"
    ]
  },
  {
    plan_type: "Premium+",
    position:  2,
    amounts:   "75 per day",
    features: [
      "global feeds",
      "Local feeds 30 km (R)",
      "Job visibility (1-30 km) -> unlimited",
      "Local feed -> unlimited",
      "Disappear (no) -> Can Renew",
      "Show in search through out the globe",
      "Offers -> unlimited",
      "post on any location",
      "Free domain and Domain Edit page",
      "up to 20 Domain uploads"
    ]
  }
]

plans.each do |attrs|
  SubscriptionPlan.find_or_create_by!(plan_type: attrs[:plan_type]) do |p|
    p.amounts   = attrs[:amounts]
    p.features  = attrs[:features]
    p.position  = attrs[:position]
    p.is_active = true
  end
end
