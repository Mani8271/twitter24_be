ActiveAdmin.register SubscriptionPlan do
  menu label: "Subscription Plans", priority: 3

  permit_params :plan_type, :amounts, :position, :is_active,
                features: [],
                limits: SubscriptionPlan::FEATURES,
                ranges: SubscriptionPlan::FEATURES

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
        span "Active", style: "display:inline-block;padding:2px 10px;border-radius:999px;font-size:12px;font-weight:700;color:#16a34a;background:#dcfce7;border:1px solid #16a34a33;"
      else
        span "Inactive", style: "display:inline-block;padding:2px 10px;border-radius:999px;font-size:12px;font-weight:700;color:#dc2626;background:#fee2e2;border:1px solid #dc262633;"
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
        row :id; row :plan_type; row :amounts; row :position; row :is_active
        row :created_at; row :updated_at
      end
    end

    panel "Features, Limits & Ranges" do
      table_for SubscriptionPlan::FEATURES do
        column("Feature")   { |key| SubscriptionPlan::FEATURE_LABELS[key] || key }
        column("Enabled")   { |key| resource.has_feature?(key) ? "✅ Yes" : "—" }
        column("Post Limit") do |key|
          next span("—", style: "color:#94a3b8") unless resource.has_feature?(key)
          val = resource.limit_for(key)
          val ? "#{val} posts" : "Unlimited"
        end
        column("Range (km)") do |key|
          next span("—", style: "color:#94a3b8") unless resource.has_feature?(key)
          val = resource.range_for(key)
          val ? "#{val} km" : "Unlimited"
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
      f.input :amounts,   hint: "e.g. '20 per day'"
      f.input :position,  hint: "Lower number = shown first (0, 1, 2 ...)"
      f.input :is_active, as: :boolean
    end

    f.inputs "Features, Limits & Ranges" do
      para style: "margin-bottom:16px;color:#64748b;font-size:13px;line-height:1.6;" do
        text_node "Enable features using the checkbox. Optionally set a Post Limit or Range (km) — toggle each with its own checkbox. Leave toggles off for no restriction (unlimited)."
      end

      # Inline JS helpers — defined once, reused per row
      text_node(<<~HTML.html_safe)
        <script>
          function toggleFeatureRow(key, checked) {
            var row = document.getElementById('row-' + key);
            var inputs = row.querySelectorAll('input:not([type=checkbox])');
            var subChks = row.querySelectorAll('.sub-chk');
            subChks.forEach(function(c) { c.disabled = !checked; c.style.opacity = checked ? '1' : '0.35'; });
            inputs.forEach(function(i) {
              // keep inputs disabled unless their own sub-checkbox is also checked
              var subChk = document.getElementById('set-limit-' + key);
              var rngChk = document.getElementById('set-range-' + key);
              if (!checked) { i.disabled = true; i.style.opacity = '0.35'; }
            });
            if (!checked) {
              subChks.forEach(function(c) { c.checked = false; toggleSubField(key, c.dataset.field, false); });
            }
          }

          function toggleSubField(key, field, checked) {
            var wrap = document.getElementById('wrap-' + field + '-' + key);
            var input = document.getElementById('input-' + field + '-' + key);
            if (checked) {
              wrap.style.display = 'flex';
              input.disabled = false;
              input.style.opacity = '1';
            } else {
              wrap.style.display = 'none';
              input.disabled = true;
              // clear value so backend receives blank → nil
              input.value = '';
            }
          }
        </script>
      HTML

      div style: "overflow-x:auto;" do
        table style: "width:100%;border-collapse:collapse;font-size:14px;" do
          thead do
            tr style: "background:#f8fafc;border-bottom:2px solid #e2e8f0;" do
              th style: "padding:10px 16px;text-align:left;color:#475569;font-weight:600;" do
                text_node "Feature"
              end
              th style: "padding:10px 16px;text-align:center;color:#475569;font-weight:600;width:80px;" do
                text_node "Enable"
              end
              th style: "padding:10px 16px;text-align:left;color:#475569;font-weight:600;width:220px;" do
                text_node "Post Limit"
              end
              th style: "padding:10px 16px;text-align:left;color:#475569;font-weight:600;width:220px;" do
                text_node "Range (km)"
              end
            end
          end

          tbody do
            SubscriptionPlan::FEATURES.each do |key|
              label     = SubscriptionPlan::FEATURE_LABELS[key] || key
              enabled   = f.object.has_feature?(key)
              cur_limit = f.object.limits&.dig(key)
              cur_range = f.object.ranges&.dig(key)
              has_limit = cur_limit.present?
              has_range = cur_range.present?

              tr id: "row-#{key}", style: "border-bottom:1px solid #e2e8f0;vertical-align:middle;" do

                # Feature name
                td style: "padding:12px 16px;color:#1e293b;font-weight:500;" do
                  text_node label
                end

                # Enable checkbox
                td style: "padding:12px 16px;text-align:center;" do
                  text_node(
                    "<input type='checkbox' name='subscription_plan[features][]' value='#{key}' " \
                    "#{enabled ? "checked" : ""} " \
                    "onchange=\"toggleFeatureRow('#{key}', this.checked)\" " \
                    "style='width:18px;height:18px;cursor:pointer;'>".html_safe
                  )
                end

                # Post Limit cell
                td style: "padding:8px 16px;" do
                  limit_display = has_limit ? "flex" : "none"
                  text_node(<<~HTML.html_safe)
                    <label style="display:flex;align-items:center;gap:8px;margin:0;">
                      <input type="checkbox" id="set-limit-#{key}" class="sub-chk" data-field="limit"
                        #{has_limit ? "checked" : ""}
                        #{enabled ? "" : "disabled style='opacity:0.35;'"}
                        onchange="toggleSubField('#{key}', 'limit', this.checked)"
                        style="width:16px;height:16px;cursor:pointer;flex-shrink:0;">
                      <span style="font-size:12px;color:#64748b;white-space:nowrap;">Set Limit</span>
                    </label>
                    <div id="wrap-limit-#{key}" style="display:#{limit_display};align-items:center;gap:6px;margin-top:6px;">
                      <input type="number" id="input-limit-#{key}" name="subscription_plan[limits][#{key}]"
                        value="#{cur_limit}" min="0"
                        #{enabled && has_limit ? "" : "disabled"}
                        style="width:100px;padding:6px 10px;border:1px solid #cbd5e1;border-radius:6px;font-size:13px;outline:none;">
                      <span style="font-size:12px;color:#94a3b8;">posts</span>
                    </div>
                  HTML
                end

                # Range (km) cell
                td style: "padding:8px 16px;" do
                  range_display = has_range ? "flex" : "none"
                  text_node(<<~HTML.html_safe)
                    <label style="display:flex;align-items:center;gap:8px;margin:0;">
                      <input type="checkbox" id="set-range-#{key}" class="sub-chk" data-field="range"
                        #{has_range ? "checked" : ""}
                        #{enabled ? "" : "disabled style='opacity:0.35;'"}
                        onchange="toggleSubField('#{key}', 'range', this.checked)"
                        style="width:16px;height:16px;cursor:pointer;flex-shrink:0;">
                      <span style="font-size:12px;color:#64748b;white-space:nowrap;">Set Range</span>
                    </label>
                    <div id="wrap-range-#{key}" style="display:#{range_display};align-items:center;gap:6px;margin-top:6px;">
                      <input type="number" id="input-range-#{key}" name="subscription_plan[ranges][#{key}]"
                        value="#{cur_range}" min="0"
                        #{enabled && has_range ? "" : "disabled"}
                        style="width:100px;padding:6px 10px;border:1px solid #cbd5e1;border-radius:6px;font-size:13px;outline:none;">
                      <span style="font-size:12px;color:#94a3b8;">km</span>
                    </div>
                  HTML
                end

              end
            end
          end
        end
      end
    end

    f.actions
  end
end
