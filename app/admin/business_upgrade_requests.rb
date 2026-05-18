ActiveAdmin.register BusinessUpgradeRequest do
  menu label: "Upgrade Requests", priority: 3

  permit_params :rejection_reason

  actions :index, :show

  # ─── Scopes ──────────────────────────────────────────────────────────────
  scope :all, default: true
  scope("Pending")  { |q| q.pending  }
  scope("Approved") { |q| q.approved }
  scope("Rejected") { |q| q.rejected }

  # ─── Filters ─────────────────────────────────────────────────────────────
  filter :request_status, as: :select, collection: BusinessUpgradeRequest::STATUSES
  filter :requested_at
  filter :approved_by
  filter :approved_at
  filter :rejected_by
  filter :rejected_at
  filter :created_at

  # ─── Index ───────────────────────────────────────────────────────────────
  index do
    column :id
    column "User" do |req|
      user = req.user
      link_to "#{user.name} (#{user.phone_number})", admin_user_path(user)
    rescue
      "Unknown"
    end
    column "Account Type" do |req|
      req.user.account_type
    rescue
      "—"
    end
    column :request_status do |req|
      color = { "pending" => "orange", "approved" => "green", "rejected" => "crimson" }[req.request_status]
      span req.request_status.capitalize, style: "color: #{color}; font-weight: bold;"
    end
    column :requested_at
    column "Reviewed By" do |req|
      case req.request_status
      when "approved" then req.approved_by
      when "rejected" then req.rejected_by
      end
    end
    column "Reviewed At" do |req|
      case req.request_status
      when "approved" then req.approved_at
      when "rejected" then req.rejected_at
      end
    end
    actions defaults: false do |req|
      item "View", admin_business_upgrade_request_path(req), class: "member_link"
      if req.request_status == "pending"
        item "Approve", approve_admin_business_upgrade_request_path(req),
             method: :put,
             data: { confirm: "Approve this upgrade request? The user will be immediately converted to a business account and their current session will be invalidated." },
             class: "member_link"
        item "Reject", reject_admin_business_upgrade_request_path(req), class: "member_link"
      end
    end
  end

  # ─── Show ────────────────────────────────────────────────────────────────
  show do
    panel "Request Details" do
      attributes_table_for resource do
        row :id
        row :request_status do
          color = { "pending" => "orange", "approved" => "green", "rejected" => "crimson" }[resource.request_status]
          span resource.request_status.capitalize, style: "color: #{color}; font-weight: bold;"
        end
        row :requested_at

        if resource.request_status == "approved"
          row :approved_by
          row :approved_at
        end

        if resource.request_status == "rejected"
          row :rejected_by
          row :rejected_at
          row :rejection_reason do
            div style: "background: #fff3cd; border: 1px solid #ffc107; border-radius: 4px; padding: 10px;" do
              resource.rejection_reason
            end
          end
        end

        row :created_at
        row :updated_at
      end
    end

    panel "User Details" do
      attributes_table_for resource.user do
        row :id
        row :name
        row :email
        row :phone_number
        row :account_type
        row :is_active
        row :created_at
      end
    end

    if resource.request_status == "pending"
      div style: "margin: 16px 0;" do
        span do
          link_to "Approve Request", approve_admin_business_upgrade_request_path(resource),
                  method: :put,
                  data: { confirm: "Approve this upgrade request?" },
                  class: "button",
                  style: "background: #2e7d32; color: white; padding: 8px 16px; border-radius: 4px; text-decoration: none; margin-right: 8px;"
        end
        span do
          link_to "Reject Request", reject_admin_business_upgrade_request_path(resource),
                  class: "button",
                  style: "background: #c62828; color: white; padding: 8px 16px; border-radius: 4px; text-decoration: none;"
        end
      end
    end
  end

  # ─── Approve ─────────────────────────────────────────────────────────────
  member_action :approve, method: :put do
    req = resource

    unless req.request_status == "pending"
      redirect_to admin_business_upgrade_requests_path, alert: "This request is not pending and cannot be approved."
      return
    end

    ActiveRecord::Base.transaction do
      user = req.user

      user.update_columns(
        account_type:  "business",
        token_version: user.token_version + 1
      )

      user.reload

      unless user.business
        user.create_business!(status: "draft", products_services: [])
      end

      unless user.onboarding_progress
        OnboardingProgress.create!(
          user_id:         user.id,
          business_id:     user.business.id,
          current_step:    1,
          steps_completed: []
        )
      end

      req.update!(
        request_status: "approved",
        approved_by:    current_admin_user.email,
        approved_at:    Time.current
      )
    end

    redirect_to admin_business_upgrade_requests_path,
                notice: "Request approved. #{resource.user.name} has been upgraded to a business account and their session has been invalidated."
  rescue => e
    redirect_to admin_business_upgrade_requests_path, alert: "Approval failed: #{e.message}"
  end

  # ─── Reject (form) ───────────────────────────────────────────────────────
  member_action :reject, method: :get do
    @business_upgrade_request = resource
    render :reject
  end

  member_action :do_reject, method: :post do
    req = resource

    unless req.request_status == "pending"
      redirect_to admin_business_upgrade_requests_path, alert: "This request is not pending."
      return
    end

    reason = params[:rejection_reason].presence

    if reason.blank?
      @business_upgrade_request = req
      flash.now[:error] = "Rejection reason is required. Please explain why this request is being rejected."
      render :reject
      return
    end

    req.update!(
      request_status:   "rejected",
      rejected_by:      current_admin_user.email,
      rejected_at:      Time.current,
      rejection_reason: reason
    )

    redirect_to admin_business_upgrade_requests_path,
                notice: "Request rejected. #{req.user.name} has been notified."
  rescue => e
    redirect_to admin_business_upgrade_requests_path, alert: "Rejection failed: #{e.message}"
  end
end
