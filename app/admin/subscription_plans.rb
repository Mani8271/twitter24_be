ActiveAdmin.register SubscriptionPlan do
  menu label: "Subscription Plans", priority: 3

  permit_params :plan_type, :amounts, :position, :is_active, features: []

  # ─── FILTERS ──────────────────────────────────────────────────────────────
  filter :plan_type
  filter :is_active
  filter :created_at

  # ─── INDEX ────────────────────────────────────────────────────────────────
  index do
    selectable_column
    id_column
    column :plan_type
    column :amounts
    column :position

    column :is_active do |plan|
      if plan.is_active
        span "Active", style: "
          display:inline-block; padding:2px 10px; border-radius:999px;
          font-size:12px; font-weight:700;
          color:#16a34a; background:#dcfce7;
          border:1px solid #16a34a33;
        "
      else
        span "Inactive", style: "
          display:inline-block; padding:2px 10px; border-radius:999px;
          font-size:12px; font-weight:700;
          color:#dc2626; background:#fee2e2;
          border:1px solid #dc262633;
        "
      end
    end

    column("Subscribers") { |plan| plan.users.count }
    column :updated_at

    actions
  end

  # ─── SHOW ─────────────────────────────────────────────────────────────────
  show do
    panel "Plan Details" do
      attributes_table_for resource do
        row :id
        row :plan_type
        row :amounts
        row :position
        row :is_active
        row :created_at
        row :updated_at
      end
    end

    panel "Features" do
      ul do
        (resource.features || []).each do |feature|
          li feature
        end
      end
    end

    panel "Subscribers" do
      para "Total users on this plan: #{resource.users.count}"
    end
  end

  # ─── FORM ─────────────────────────────────────────────────────────────────
  form do |f|
    f.inputs "Plan Details" do
      f.input :plan_type
      f.input :amounts, hint: "e.g. '20 per day'"
      f.input :position, hint: "Lower number = shown first (0, 1, 2 ...)"
      f.input :is_active, as: :boolean
    end

    f.inputs "Features (one per line)" do
      f.input :features,
              as: :text,
              input_html: {
                value: (f.object.features || []).join("\n"),
                rows: 12,
                id: "features_textarea"
              },
              hint: "Enter each feature on a new line"
    end

    f.actions
  end

  # ─── BEFORE SAVE: convert textarea newlines → array ──────────────────────
  before_save do |plan|
    raw = params[:subscription_plan][:features]
    if raw.is_a?(String)
      plan.features = raw.split("\n").map(&:strip).reject(&:blank?)
    end
  end
end
