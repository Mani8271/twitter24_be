ActiveAdmin.register SubscriptionPlan do
  menu label: "Subscription Plans", priority: 3

  permit_params :plan_type, :amounts, :position, :is_active,
                features: [],
                limits: SubscriptionPlan::FEATURES,
                ranges: SubscriptionPlan::FEATURES,
                disappear_days: SubscriptionPlan::FEATURES

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

    panel "Post Expiry (Disappear in Days)" do
      table_for SubscriptionPlan::DISAPPEARABLE_FEATURES do
        column("Feature") { |key| SubscriptionPlan::FEATURE_LABELS[key] || key }
        column("Enabled") { |key| resource.has_feature?(key) ? "✅ Yes" : "—" }
        column("Disappear in Days") do |key|
          next span("—", style: "color:#94a3b8") unless resource.has_feature?(key)
          val = resource.disappear_days_for(key)
          val ? "#{val} days" : "Never"
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

      # ── Feature Guide ──────────────────────────────────────────────────────
      text_node(<<~HTML.html_safe)
        <details style="margin-bottom:20px;border:1px solid #e2e8f0;border-radius:10px;overflow:hidden;">
          <summary style="padding:12px 16px;background:#f8fafc;cursor:pointer;font-size:13px;font-weight:600;color:#334155;list-style:none;display:flex;align-items:center;gap:8px;">
            &#9432;&nbsp; Feature Guide — click to expand
          </summary>
          <div style="padding:16px;display:grid;gap:12px;font-size:13px;line-height:1.65;color:#475569;">

            <div style="display:grid;grid-template-columns:180px 1fr;gap:8px;align-items:start;padding-bottom:10px;border-bottom:1px solid #f1f5f9;">
              <span style="font-weight:700;color:#1e293b;">Global Feed</span>
              <span>Business can publish posts visible across the entire platform, regardless of location. Use <em>Post Limit</em> to cap how many global posts they can create per subscription period. Use <em>Range</em> to restrict how far (in km) those posts are discoverable.</span>
            </div>

            <div style="display:grid;grid-template-columns:180px 1fr;gap:8px;align-items:start;padding-bottom:10px;border-bottom:1px solid #f1f5f9;">
              <span style="font-weight:700;color:#1e293b;">Local Feed</span>
              <span>Business can publish posts visible only to users within their local area (defined by the business location + reach distance). Use <em>Post Limit</em> to cap how many local posts they can create. Use <em>Range</em> to set the maximum radius (km) those posts travel.</span>
            </div>

            <div style="display:grid;grid-template-columns:180px 1fr;gap:8px;align-items:start;padding-bottom:10px;border-bottom:1px solid #f1f5f9;">
              <span style="font-weight:700;color:#1e293b;">Job Posts</span>
              <span>Business can post job listings. Use <em>Post Limit</em> to cap the number of active job listings allowed at once. Use <em>Range</em> to restrict how far (in km) job listings are discoverable to job seekers.</span>
            </div>

            <div style="display:grid;grid-template-columns:180px 1fr;gap:8px;align-items:start;padding-bottom:10px;border-bottom:1px solid #f1f5f9;">
              <span style="font-weight:700;color:#1e293b;">Offers</span>
              <span>Business can post promotional offers or deals. Use <em>Post Limit</em> to cap how many active offers they can run at a time. Use <em>Range</em> to restrict offer visibility to users within a given km radius.</span>
            </div>

            <div style="display:grid;grid-template-columns:180px 1fr;gap:8px;align-items:start;padding-bottom:10px;border-bottom:1px solid #f1f5f9;">
              <span style="font-weight:700;color:#1e293b;">Post by Radius</span>
              <span>Controls how far a post is discoverable from the business's location. When this feature is enabled, the <em>Range</em> value (km) you set here is the maximum radius within which other users can see that post. Example: Range = 10 km means only users within 10 km of the business will see the post in their feed. Leave Range blank for unlimited reach.</span>
            </div>

            <div style="display:grid;grid-template-columns:180px 1fr;gap:8px;align-items:start;padding-bottom:10px;border-bottom:1px solid #f1f5f9;">
              <span style="font-weight:700;color:#1e293b;">Domain Page</span>
              <span>The business gets a dedicated public profile / storefront page on the platform (e.g. their brand page that customers can follow and review). This is an <strong>on/off access flag</strong> — it is either granted or not. <em>Post Limit</em> and <em>Range</em> are not applicable here; leave them blank. Simply enable the checkbox to grant access.</span>
            </div>

            <div style="display:grid;grid-template-columns:180px 1fr;gap:8px;align-items:start;padding-bottom:10px;border-bottom:1px solid #f1f5f9;">
              <span style="font-weight:700;color:#1e293b;">Post from Any Location</span>
              <span>By default, when a business creates a post the app automatically attaches their registered business location to it. With this feature enabled, the business can instead pick <strong>any custom location</strong> on the map at the time of posting — useful for businesses that operate from multiple sites or want to target a different area. This is an <strong>on/off flag</strong>; no Limit or Range needed.</span>
            </div>

            <div style="display:grid;grid-template-columns:180px 1fr;gap:8px;align-items:start;padding-bottom:10px;border-bottom:1px solid #f1f5f9;">
              <span style="font-weight:700;color:#1e293b;">Global Search Visibility</span>
              <span>When enabled, this business's profile and posts appear in platform-wide search results for all users, not just those in their local area. This is an <strong>on/off flag</strong>; no Limit or Range needed.</span>
            </div>

            <div style="display:grid;grid-template-columns:180px 1fr;gap:8px;align-items:start;">
              <span style="font-weight:700;color:#1e293b;">Domain Uploads</span>
              <span>The number of images / media files the business is allowed to upload to their Domain Page (storefront / shop gallery). Use <em>Post Limit</em> to set the maximum number of images they can have on their domain page at any one time. Example: Limit = 10 means they can upload up to 10 shop images. Leave blank for unlimited uploads. <em>Range</em> is not applicable here.</span>
            </div>

          </div>
        </details>
      HTML

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
              th style: "padding:10px 16px;text-align:left;color:#475569;font-weight:600;width:220px;" do
                text_node "Disappear in Days"
              end
            end
          end

          tbody do
            SubscriptionPlan::FEATURES.each do |key|
              label        = SubscriptionPlan::FEATURE_LABELS[key] || key
              enabled      = f.object.has_feature?(key)
              cur_limit    = f.object.limits&.dig(key)
              cur_range    = f.object.ranges&.dig(key)
              cur_disappear = f.object.disappear_days&.dig(key)
              has_limit    = cur_limit.present?
              has_range    = cur_range.present?
              has_disappear = cur_disappear.present?

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

                # Disappear in Days cell — only for supported features
                td style: "padding:8px 16px;" do
                  if SubscriptionPlan::DISAPPEARABLE_FEATURES.include?(key)
                    disappear_display = has_disappear ? "flex" : "none"
                    text_node(<<~HTML.html_safe)
                      <label style="display:flex;align-items:center;gap:8px;margin:0;">
                        <input type="checkbox" id="set-disappear-#{key}" class="sub-chk" data-field="disappear"
                          #{has_disappear ? "checked" : ""}
                          #{enabled ? "" : "disabled style='opacity:0.35;'"}
                          onchange="toggleSubField('#{key}', 'disappear', this.checked)"
                          style="width:16px;height:16px;cursor:pointer;flex-shrink:0;">
                        <span style="font-size:12px;color:#64748b;white-space:nowrap;">Set Days</span>
                      </label>
                      <div id="wrap-disappear-#{key}" style="display:#{disappear_display};align-items:center;gap:6px;margin-top:6px;">
                        <input type="number" id="input-disappear-#{key}" name="subscription_plan[disappear_days][#{key}]"
                          value="#{cur_disappear}" min="1"
                          #{enabled && has_disappear ? "" : "disabled"}
                          style="width:100px;padding:6px 10px;border:1px solid #cbd5e1;border-radius:6px;font-size:13px;outline:none;">
                        <span style="font-size:12px;color:#94a3b8;">days</span>
                      </div>
                    HTML
                  else
                    span "—", style: "color:#94a3b8;font-size:13px;"
                  end
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
