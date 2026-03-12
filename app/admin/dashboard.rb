# frozen_string_literal: true
ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: "Admin Dashboard" do

    # ── STAT CARDS ────────────────────────────────────────────────────────────
    columns do
      column do
        panel "Pending Approval" do
          count = Business.where(status: "submitted").count
          div style: "text-align:center; padding:16px 0;" do
            span count.to_s, style: "font-size:48px; font-weight:800; color:#d97706;"
            br
            span "Businesses waiting review", style: "font-size:13px; color:#6b7280;"
            br
            br
            link_to "Review Now →",
                    admin_businesses_path(scope: "pending_review"),
                    style: "background:#d97706; color:#fff; padding:8px 20px; border-radius:8px;
                            font-weight:700; text-decoration:none; font-size:13px;"
          end
        end
      end

      column do
        panel "Approved Businesses" do
          count = Business.where(status: "approved").count
          div style: "text-align:center; padding:16px 0;" do
            span count.to_s, style: "font-size:48px; font-weight:800; color:#16a34a;"
            br
            span "Live on the platform", style: "font-size:13px; color:#6b7280;"
          end
        end
      end

      column do
        panel "Total Users" do
          users   = User.where(account_type: "user").count
          biz_users = User.where(account_type: "business").count
          div style: "text-align:center; padding:16px 0;" do
            span (users + biz_users).to_s, style: "font-size:48px; font-weight:800; color:#7c3aed;"
            br
            span "#{users} regular · #{biz_users} business", style: "font-size:13px; color:#6b7280;"
          end
        end
      end

      column do
        panel "Draft (Incomplete)" do
          count = Business.where(status: "draft").count
          div style: "text-align:center; padding:16px 0;" do
            span count.to_s, style: "font-size:48px; font-weight:800; color:#6b7280;"
            br
            span "Onboarding not complete", style: "font-size:13px; color:#6b7280;"
          end
        end
      end
    end

    # ── PENDING BUSINESSES TABLE ───────────────────────────────────────────────
    panel "Businesses Pending Approval" do
      pending = Business.where(status: "submitted")
                        .includes(:user, :business_contact, :business_location)
                        .order(created_at: :desc)
                        .limit(20)

      if pending.any?
        table_for pending do
          column("ID")       { |b| link_to b.id, admin_business_path(b) }
          column("Name")     { |b| link_to b.name, admin_business_path(b) }
          column("Category") { |b| b.category }
          column("Owner")    { |b| b.user&.name }
          column("Phone")    { |b| b.business_contact&.contact_phone }
          column("City")     { |b| b.business_location&.city }
          column("Submitted"){ |b| b.updated_at.strftime("%d %b %Y") }
          column("Action") do |b|
            link_to "✅ Approve",
                    approve_admin_business_path(b),
                    method: :put,
                    style: "background:#16a34a; color:#fff; padding:4px 14px; border-radius:6px;
                            font-weight:700; text-decoration:none; font-size:12px;",
                    data: { confirm: "Approve #{b.name}?" }
          end
        end
      else
        div style: "text-align:center; padding:32px; color:#6b7280;" do
          span "🎉 No pending businesses. All caught up!"
        end
      end
    end

    # ── RECENTLY APPROVED ─────────────────────────────────────────────────────
    panel "Recently Approved (Last 5)" do
      recent = Business.where(status: "approved")
                       .includes(:user)
                       .order(updated_at: :desc)
                       .limit(5)

      if recent.any?
        table_for recent do
          column("ID")       { |b| link_to b.id, admin_business_path(b) }
          column("Name")     { |b| link_to b.name, admin_business_path(b) }
          column("Category") { |b| b.category }
          column("Owner")    { |b| b.user&.name }
          column("Approved") { |b| b.updated_at.strftime("%d %b %Y %H:%M") }
        end
      else
        para "No approved businesses yet."
      end
    end

  end
end
