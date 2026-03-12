ActiveAdmin.register User do
  menu label: "Users", priority: 3

  permit_params :name, :email, :phone_number, :account_type, :status

  # Show deleted users too (bypass default_scope)
  controller do
    def scoped_collection
      User.unscoped
    end

    before_action :intercept_destroy, only: [:destroy]

    def intercept_destroy
      user = User.unscoped.find(params[:id])
      user.soft_delete!
      redirect_to admin_users_path, notice: "🗑️ #{user.name} has been soft deleted."
    end
  end

  # ─── SCOPES ──────────────────────────────────────────────────────────────
  scope("All Active", default: true) { |s| s.where(deleted_at: nil) }
  scope("Regular Users")   { |s| s.where(account_type: "user", deleted_at: nil) }
  scope("Business Owners") { |s| s.where(account_type: "business", deleted_at: nil) }
  scope("Deleted")         { |s| s.where.not(deleted_at: nil) }

  # ─── FILTERS ─────────────────────────────────────────────────────────────
  filter :name
  filter :phone_number
  filter :email
  filter :account_type, as: :select, collection: %w[user business]
  filter :created_at
  filter :deleted_at

  # ─── MEMBER ACTIONS ───────────────────────────────────────────────────────
  member_action :restore, method: :put do
    User.unscoped.find(params[:id]).update_column(:deleted_at, nil)
    redirect_to admin_users_path, notice: "✅ User account restored."
  end

  # ─── INDEX ────────────────────────────────────────────────────────────────
  index do
    selectable_column
    id_column
    column :name
    column :phone_number
    column :email
    column :account_type do |u|
      color = u.account_type == "business" ? "#7c3aed" : "#2563eb"
      span u.account_type.capitalize,
           style: "color:#{color}; font-weight:700; font-size:12px;"
    end
    column "Business Status" do |u|
      if u.account_type == "business" && u.business
        colors = { "approved" => "#16a34a", "submitted" => "#d97706", "draft" => "#6b7280" }
        bg     = { "approved" => "#dcfce7", "submitted" => "#fef3c7", "draft" => "#f1f5f9" }
        s = u.business.status
        span s.capitalize, style: "
          padding:2px 10px; border-radius:999px; font-size:12px; font-weight:700;
          color:#{colors[s]}; background:#{bg[s]};
        "
      else
        span "-"
      end
    end
    column "Status" do |u|
      if u.deleted_at.present?
        span "Deleted", style: "
          padding:2px 10px; border-radius:999px; font-size:12px; font-weight:700;
          color:#dc2626; background:#fee2e2; border:1px solid #fca5a533;
        "
      else
        span "Active", style: "
          padding:2px 10px; border-radius:999px; font-size:12px; font-weight:700;
          color:#16a34a; background:#dcfce7; border:1px solid #86efac33;
        "
      end
    end
    column :deleted_at
    column :created_at
    column "Actions" do |u|
      links = [link_to("View", admin_user_path(u), class: "member_link")]
      if u.deleted_at.present?
        links << link_to("♻️ Restore",
                         restore_admin_user_path(u),
                         method: :put,
                         class: "member_link",
                         style: "color:#16a34a; font-weight:700;",
                         data: { confirm: "Restore account for #{u.name}?" })
      end
      safe_join(links, " | ")
    end
  end

  # ─── SHOW ─────────────────────────────────────────────────────────────────
  show do
    if resource.deleted_at.present?
      panel "Account Deleted" do
        div style: "display:flex; align-items:center; gap:16px; padding:8px 0;" do
          span "DELETED on #{resource.deleted_at.strftime('%d %b %Y %H:%M')}",
               style: "padding:6px 20px; border-radius:999px; font-weight:800; font-size:14px;
                       color:#dc2626; background:#fee2e2; border:1px solid #fca5a544;"
          span do
            link_to "♻️ Restore This Account",
                    restore_admin_user_path(resource),
                    method: :put,
                    class: "button",
                    style: "background:#16a34a; color:#fff; padding:8px 20px; border-radius:8px; font-weight:700; text-decoration:none;",
                    data: { confirm: "Restore account for #{resource.name}?" }
          end
        end
      end
    end

    columns do
      column do
        panel "User Details" do
          attributes_table_for resource do
            row :id
            row :name
            row :phone_number
            row :email
            row :account_type
            row :deleted_at
            row :created_at
          end
        end
      end
      column do
        if resource.account_type == "business" && resource.business
          panel "Business" do
            b = resource.business
            attributes_table_for b do
              row :name
              row :category
              row :status do
                colors = { "approved" => "#16a34a", "submitted" => "#d97706", "draft" => "#6b7280" }
                span b.status.capitalize, style: "color:#{colors[b.status]}; font-weight:700;"
              end
              row("View") { link_to "Open Business →", admin_business_path(b) }
            end
          end
        end
      end
    end
  end

  # ─── FORM ────────────────────────────────────────────────────────────────
  form do |f|
    f.inputs "User Details" do
      f.input :name
      f.input :phone_number
      f.input :email
      f.input :account_type, as: :select,
              collection: [["User", "user"], ["Business", "business"]]
    end
    f.actions
  end
end
