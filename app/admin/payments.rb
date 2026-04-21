ActiveAdmin.register Payment do
  menu priority: 4, label: "Payments"

  permit_params :status

  # ─── SCOPES ────────────────────────────────────────────────────────────────
  scope("All",     default: true) { |s| s.all }
  scope("Success") { |s| s.where(status: "success") }
  scope("Pending") { |s| s.where(status: "pending") }
  scope("Failed")  { |s| s.where(status: "failed") }

  # ─── FILTERS ───────────────────────────────────────────────────────────────
  filter :status, as: :select, collection: Payment::STATUSES
  filter :subscription_plan
  filter :merchant_transaction_id
  filter :amount_in_paise
  filter :paid_at
  filter :created_at

  # ─── INDEX ─────────────────────────────────────────────────────────────────
  index do
    selectable_column
    id_column

    column "User" do |p|
      if p.user
        link_to p.user.name, admin_user_path(p.user)
      else
        span "—"
      end
    end

    column "Phone" do |p|
      p.user&.phone_number || "—"
    end

    column "Plan" do |p|
      span p.subscription_plan.plan_type.upcase,
           style: "font-weight:700; font-size:12px; color:#7c3aed;"
    end

    column "Amount" do |p|
      span "₹#{p.amount_in_rupees}",
           style: "font-weight:700;"
    end

    column "Status" do |p|
      colors = {
        "success" => ["#16a34a", "#dcfce7", "#86efac44"],
        "pending" => ["#d97706", "#fef3c7", "#fcd34d44"],
        "failed"  => ["#dc2626", "#fee2e2", "#fca5a544"]
      }
      c = colors[p.status] || ["#6b7280", "#f1f5f9", "#e5e7eb"]
      span p.status.capitalize,
           style: "padding:2px 12px; border-radius:999px; font-size:12px; font-weight:700;
                   color:#{c[0]}; background:#{c[1]}; border:1px solid #{c[2]};"
    end

    column "Txn ID" do |p|
      span p.merchant_transaction_id,
           style: "font-size:11px; color:#64748b; font-family:monospace;"
    end

    column "Paid At" do |p|
      p.paid_at ? p.paid_at.strftime("%d %b %Y %H:%M") : "—"
    end

    column "Created" do |p|
      p.created_at.strftime("%d %b %Y %H:%M")
    end

    actions
  end

  # ─── SHOW ──────────────────────────────────────────────────────────────────
  show do
    # ── Status Banner ──
    panel "Payment Status" do
      colors = {
        "success" => ["#16a34a", "#dcfce7"],
        "pending" => ["#d97706", "#fef3c7"],
        "failed"  => ["#dc2626", "#fee2e2"]
      }
      c = colors[resource.status] || ["#6b7280", "#f1f5f9"]
      div style: "display:flex; align-items:center; gap:20px; padding:12px 0;" do
        span resource.status.upcase,
             style: "padding:8px 28px; border-radius:999px; font-weight:800;
                     font-size:16px; color:#{c[0]}; background:#{c[1]};"
        span "₹#{resource.amount_in_rupees}",
             style: "font-size:22px; font-weight:800; color:#0f172a;"
        span resource.subscription_plan.plan_type.upcase,
             style: "font-size:13px; font-weight:700; color:#7c3aed;
                     background:#ede9fe; padding:4px 14px; border-radius:999px;"
      end
    end

    columns do
      # ── Left: Payment Details ──
      column do
        panel "Transaction Details" do
          attributes_table_for resource do
            row :id
            row("Merchant Txn ID") do
              span resource.merchant_transaction_id,
                   style: "font-family:monospace; font-size:13px; color:#0f172a;"
            end
            row("PhonePe Txn ID") do
              if resource.phonepe_transaction_id.present?
                span resource.phonepe_transaction_id,
                     style: "font-family:monospace; font-size:13px; color:#0f172a;"
              else
                span "Not yet assigned", style: "color:#94a3b8;"
              end
            end
            row("Amount") { "₹#{resource.amount_in_rupees}" }
            row("GST IN") { resource.gst_in.presence || "—" }
            row("Status") { resource.status.capitalize }
            row("Paid At") do
              resource.paid_at ? resource.paid_at.strftime("%d %b %Y at %H:%M:%S") : "—"
            end
            row :created_at
            row :updated_at
          end
        end
      end

      # ── Right: User & Plan ──
      column do
        panel "User" do
          u = resource.user
          attributes_table_for u do
            row("Name")   { link_to u.name, admin_user_path(u) }
            row("Phone")  { u.phone_number }
            row("Email")  { u.email.presence || "—" }
            row("Type")   { u.account_type.capitalize }
          end
        end

        panel "Subscription Plan" do
          pl = resource.subscription_plan
          attributes_table_for pl do
            row("Plan")     { pl.plan_type.upcase }
            row("Price")    { "₹#{pl.amounts} / month" }
            row("Features") { pl.features.join(", ") }
          end
        end
      end
    end

    # ── Gateway Response (full) ──
    panel "PhonePe Gateway Response" do
      if resource.gateway_response.present? && resource.gateway_response != {}
        pre style: "background:#0f172a; color:#e2e8f0; padding:20px; border-radius:10px;
                    font-size:13px; overflow-x:auto; line-height:1.6;" do
          JSON.pretty_generate(resource.gateway_response)
        end
      else
        span "No gateway response recorded.", style: "color:#94a3b8;"
      end
    end
  end

  # ─── SUMMARY PANEL on Dashboard ────────────────────────────────────────────
  sidebar "Payment Summary", only: :index do
    total     = Payment.count
    success   = Payment.where(status: "success").count
    pending   = Payment.where(status: "pending").count
    failed    = Payment.where(status: "failed").count
    revenue   = Payment.where(status: "success").sum(:amount_in_paise) / 100.0

    div style: "font-size:13px; line-height:2.2;" do
      div do
        strong "Total Transactions: "
        span total
      end
      div do
        strong style: "color:#16a34a;" do "✅ Success: " end
        span success
      end
      div do
        strong style: "color:#d97706;" do "⏳ Pending: " end
        span pending
      end
      div do
        strong style: "color:#dc2626;" do "❌ Failed: " end
        span failed
      end
      hr style: "margin:10px 0; border-color:#e2e8f0;"
      div do
        strong "Total Revenue: "
        span "₹#{revenue}", style: "font-weight:800; color:#16a34a; font-size:15px;"
      end
    end
  end
end
