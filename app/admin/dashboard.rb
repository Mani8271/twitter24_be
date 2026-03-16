# frozen_string_literal: true
ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: "Admin Dashboard" do

    # ── STAT CARDS ROW 1 ──────────────────────────────────────────────────────
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
          users     = User.where(account_type: "user").count
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

    # ── STAT CARDS ROW 2 — Jobs & Offers ──────────────────────────────────────
    columns do
      column do
        panel "Total Jobs" do
          total  = Job.count
          local  = Job.where(post_type: "local").count
          global = Job.where(post_type: "global").count
          div style: "text-align:center; padding:16px 0;" do
            span total.to_s, style: "font-size:48px; font-weight:800; color:#0369a1;"
            br
            span "#{local} local · #{global} global", style: "font-size:13px; color:#6b7280;"
            br; br
            link_to "View All Jobs →", admin_jobs_path,
                    style: "background:#0369a1; color:#fff; padding:8px 20px; border-radius:8px;
                            font-weight:700; text-decoration:none; font-size:13px;"
          end
        end
      end

      column do
        panel "Active Offers" do
          active  = Offer.where("valid_till IS NULL OR valid_till >= ?", Time.current).count
          expired = Offer.where("valid_till IS NOT NULL AND valid_till < ?", Time.current).count
          div style: "text-align:center; padding:16px 0;" do
            span active.to_s, style: "font-size:48px; font-weight:800; color:#059669;"
            br
            span "#{expired} expired", style: "font-size:13px; color:#6b7280;"
            br; br
            link_to "View All Offers →", admin_offers_path,
                    style: "background:#059669; color:#fff; padding:8px 20px; border-radius:8px;
                            font-weight:700; text-decoration:none; font-size:13px;"
          end
        end
      end

      column do
        panel "Jobs by Type" do
          types = %w[full_time part_time internship contract freelance]
          div style: "padding:8px 0;" do
            types.each do |t|
              count = Job.where(job_type: t).count
              div style: "display:flex; justify-content:space-between; padding:4px 0; border-bottom:1px solid #f1f5f9;" do
                span t.gsub("_", " ").titlecase, style: "font-size:13px; color:#374151; font-weight:600;"
                span count.to_s, style: "font-size:13px; font-weight:800; color:#7c3aed;"
              end
            end
          end
        end
      end

      column do
        panel "Offers by Type" do
          local_offers  = Offer.where(offer_type: "local").count
          global_offers = Offer.where(offer_type: "global").count
          total_offers  = Offer.count
          div style: "padding:8px 0;" do
            [["Local", local_offers, "#0369a1"], ["Global", global_offers, "#7c3aed"], ["Total", total_offers, "#374151"]].each do |label, count, color|
              div style: "display:flex; justify-content:space-between; padding:6px 0; border-bottom:1px solid #f1f5f9;" do
                span label, style: "font-size:13px; color:#374151; font-weight:600;"
                span count.to_s, style: "font-size:13px; font-weight:800; color:#{color};"
              end
            end
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

    # ── RECENT JOBS ───────────────────────────────────────────────────────────
    panel "Recent Jobs (Last 10)" do
      recent_jobs = Job.includes(:user).order(created_at: :desc).limit(10)
      if recent_jobs.any?
        table_for recent_jobs do
          column("ID")       { |j| link_to j.id, admin_job_path(j) }
          column("Title")    { |j| link_to j.job_title, admin_job_path(j) }
          column("Type")     { |j| j.job_type&.gsub("_", " ")&.titlecase }
          column("Post")     { |j| j.post_type&.capitalize }
          column("Posted By"){ |j| j.user&.name || j.user&.phone_number }
          column("Salary")   { |j| j.salary ? "₹#{j.salary.to_i}" : "—" }
          column("Posted")   { |j| j.created_at.strftime("%d %b %Y") }
        end
      else
        div style: "text-align:center; padding:24px; color:#6b7280;" do
          span "No jobs posted yet."
        end
      end
    end

    # ── RECENT OFFERS ─────────────────────────────────────────────────────────
    panel "Recent Offers (Last 10)" do
      recent_offers = Offer.includes(:user).order(created_at: :desc).limit(10)
      if recent_offers.any?
        table_for recent_offers do
          column("ID")       { |o| link_to o.id, admin_offer_path(o) }
          column("Title")    { |o| link_to o.title, admin_offer_path(o) }
          column("Type")     { |o| o.offer_type.capitalize }
          column("Posted By"){ |o| o.user&.name || o.user&.phone_number }
          column("Valid Till") do |o|
            if o.valid_till.nil?
              span "No expiry", style: "color:#6b7280; font-size:12px;"
            elsif o.valid_till < Time.current
              span "Expired", style: "color:#dc2626; font-weight:700; font-size:12px;"
            else
              span o.valid_till.strftime("%d %b %Y"), style: "color:#16a34a; font-weight:700; font-size:12px;"
            end
          end
          column("Posted")   { |o| o.created_at.strftime("%d %b %Y") }
        end
      else
        div style: "text-align:center; padding:24px; color:#6b7280;" do
          span "No offers posted yet."
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
