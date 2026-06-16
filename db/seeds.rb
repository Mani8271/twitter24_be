# # # This file should ensure the existence of records required to run the application in every environment (production,
# # # development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# # # The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
# # #
# # # Example:
# # #
# # #   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
# # #     MovieGenre.find_or_create_by!(name: genre_name)
# # #   end

# # AdminUser.find_or_create_by!(email: 'twitter24official@gmail.com') do |u|
# #   u.password              = 'Twitter24'
# #   u.password_confirmation = 'Twitter24'
# # end

# # ─── Legal Content ─────────────────────────────────────────────────────────────
# TERMS_HTML = <<~HTML
#   <style>
#     .terms-container { font-family: inherit; line-height: 1.7; }
#     .terms-container h2 { margin-top: 16px; font-size: 18px; border-left: 4px solid #9333EA; padding-left: 10px; }
#     .terms-container p { margin: 10px 0; font-size: 14px; }
#     .terms-container ul { margin: 10px 0 20px 20px; font-size: 14px; }
#     .terms-container li { margin-bottom: 6px; }
#     .terms-container .section { margin-bottom: 20px; }
#     .terms-container .highlight { font-weight: bold; }
#   </style>
#   <div class="terms-container">
#     <div class="section"><h2>1. Acceptance of Terms</h2><p>By using Witter24, you agree to these Terms, our Privacy Policy, and all applicable Indian laws, including the Information Technology Act, 2000, IT Rules 2021, and DPDP Act 2023.</p></div>
#     <div class="section"><h2>2. Nature of Platform</h2><p>Witter24 is a hyperlocal community, updates, jobs, marketplace, and social utility platform.</p><p>Witter24 functions as an intermediary under Indian law and exercises due diligence over user-generated content.</p></div>
#     <div class="section"><h2>3. User Eligibility</h2><ul><li>Users must be 18+</li><li>Minors require verifiable parental consent</li><li>No fake, bot, or impersonation accounts</li><li>Accurate registration information is mandatory</li></ul><p>This supports DPDP child-data protection obligations.</p></div>
#     <div class="section"><h2>4. Acceptable Use</h2><p>Users shall not post or transmit:</p><ul><li>Illegal content</li><li>Hate speech</li><li>Obscenity</li><li>Defamation</li><li>Fake jobs</li><li>Fraudulent marketplace listings</li><li>Malware / phishing links</li><li>Misinformation</li><li>Unlawful political manipulation</li><li>Content threatening public order</li></ul></div>
#     <div class="section"><h2>5. Hyperlocal Safety</h2><p>Misuse for stalking, doxxing, tracking minors, or targeted harassment is strictly prohibited. Violations may lead to immediate suspension, police complaint, or lawful disclosure to cybercrime authorities.</p></div>
#     <div class="section"><h2>6. Marketplace &amp; Jobs Disclaimer</h2><p>Witter24 only provides listing infrastructure. We are not a party to employment contracts, buyer-seller disputes, or payment disputes. Users must independently verify all transactions.</p></div>
#     <div class="section"><h2>7. User Content License</h2><p>Users retain ownership of their content. By posting, users grant Witter24 a non-exclusive, revocable, worldwide, royalty-free license to host, display, and distribute content within the platform.</p></div>
#     <div class="section"><h2>8. Grievance Officer</h2><p>Witter24 shall appoint a Grievance Officer as required by IT Rules 2021. Acknowledgement: 24 hours. Action: 15 days.</p></div>
#     <div class="section"><h2>9. Suspension &amp; Takedown</h2><p>We may suspend accounts for repeated violations, fraud, cyber abuse, fake emergency alerts, marketplace scams, legal notices, or government requests.</p></div>
#     <div class="section"><h2>10. Governing Law</h2><p>These Terms are governed by the laws of India.</p></div>
#   </div>
# HTML

# PRIVACY_HTML = <<~HTML
#   <style>
#     .privacy-container { font-family: inherit; line-height: 1.7; }
#     .privacy-container h2 { margin-top: 16px; font-size: 18px; border-left: 4px solid #9333EA; padding-left: 10px; }
#     .privacy-container h3 { font-size: 15px; margin-top: 12px; font-weight: 600; }
#     .privacy-container p { margin: 10px 0; font-size: 14px; }
#     .privacy-container ul { margin: 10px 0 20px 20px; font-size: 14px; }
#     .privacy-container li { margin-bottom: 6px; }
#     .privacy-container .section { margin-bottom: 20px; }
#     .privacy-container .bold { font-weight: bold; }
#   </style>
#   <div class="privacy-container">
#     <div class="section"><h2>1. Data We Collect</h2><h3>Account Information</h3><ul><li>Name</li><li>Phone number</li><li>Email address</li><li>Profile image</li><li>Date of birth</li></ul><h3>Location Information</h3><ul><li>GPS coordinates</li><li>City or locality</li><li>Nearby radius</li></ul><h3>Platform Activity</h3><ul><li>Posts, comments, likes, and shares</li><li>Marketplace chats</li><li>Job applications</li></ul></div>
#     <div class="section"><h2>2. Purpose of Data Processing</h2><p>We process user data for nearby feed ranking, emergency alerts, job discovery, fraud prevention, AI-based personalization, and analytics. All processing is under the DPDP Act, 2023.</p></div>
#     <div class="section"><h2>3. User Rights</h2><ul><li>Right to access personal data</li><li>Right to correct inaccurate data</li><li>Right to request deletion</li><li>Right to withdraw consent</li><li>Right to grievance redressal</li></ul></div>
#     <div class="section"><h2>4. Children's Privacy</h2><p>Users below 18 must provide verifiable parental consent. We do not engage in behavioral tracking of minors.</p></div>
#     <div class="section"><h2>5. Data Sharing</h2><p>We may share data with cloud providers, payment partners, fraud detection systems, and legal authorities. <span class="bold">We do not sell personal user data to any third party.</span></p></div>
#     <div class="section"><h2>6. Security Controls</h2><ul><li>Encryption at rest</li><li>Secure HTTPS transmission</li><li>Access control mechanisms</li><li>Audit logging</li><li>CERT-In aligned reporting</li></ul></div>
#     <div class="section"><h2>7. Data Retention</h2><p>We retain personal data only for operational requirements, fraud prevention, customer support, and legal compliance. Data is securely deleted or anonymized after the retention period.</p></div>
#     <div class="section"><h2>8. Contact Information</h2><p>For privacy or legal concerns: <a href="mailto:legal@witter24.in">legal@witter24.in</a> | <a href="mailto:privacy@witter24.in">privacy@witter24.in</a> | <a href="mailto:grievance@witter24.in">grievance@witter24.in</a></p></div>
#     <div class="section"><h2>9. Community Guidelines</h2><ul><li>No hate speech</li><li>No scams or fraud</li><li>No stalking or harassment</li><li>No fake job postings</li><li>No false emergency alerts</li><li>No impersonation</li></ul></div>
#   </div>
# HTML

# puts "Seeding legal content..."

# terms = Content.find_or_initialize_by(title: "terms_and_conditions")
# terms.subtitle = "Terms & Conditions"
# terms.content  = TERMS_HTML.strip
# terms.save!

# privacy = Content.find_or_initialize_by(title: "privacy_policy")
# privacy.subtitle = "Privacy Policy"
# privacy.content  = PRIVACY_HTML.strip
# privacy.save!

# puts "✓ Legal content seeded."

# # AdminUser.find_or_create_by!(email: 'twitter24@gmail.com') do |u|
# #   u.password = 'Twitter24'
# #   u.password_confirmation = 'Twitter24'
# # end



# # # ─── Subscription Plans ────────────────────────────────────────────────────
# # # plans = [
# # #   {
# # #     plan_type: "Basic",
# # #     position:  0,
# # #     amounts:   "20 per day",
# # #     features:  %w[global_feed local_feed job_posts offers post_radius],
# # #     limits:    { "offers" => 10, "job_posts" => 5, "local_feed" => 30 },
# # #     ranges:    { "local_feed" => 25, "post_radius" => 25, "offers" => 25, "job_posts" => 25 }
# # #   },
# # #   {
# # #     plan_type: "Premium",
# # #     position:  1,
# # #     amounts:   "35 per day",
# # #     features:  %w[global_feed local_feed job_posts offers post_radius],
# # #     limits:    { "offers" => 20, "job_posts" => 10, "local_feed" => 50 },
# # #     ranges:    { "local_feed" => 50, "post_radius" => 50, "offers" => 50, "job_posts" => 50 }
# # #   },
# # #   {
# # #     plan_type: "Premium+",
# # #     position:  2,
# # #     amounts:   "75 per day",
# # #     features:  %w[global_feed local_feed job_posts offers post_radius
# # #                   domain_page post_anywhere global_search domain_uploads],
# # #     limits:    { "domain_uploads" => 20 },
# # #     ranges:    {}  # unlimited range for all features
# # #   }
# # # ]

# # # plans.each do |attrs|
# # #   plan = SubscriptionPlan.find_or_initialize_by(plan_type: attrs[:plan_type])
# # #   plan.amounts   = attrs[:amounts]
# # #   plan.features  = attrs[:features]
# # #   plan.limits    = attrs[:limits]
# # #   plan.ranges    = attrs[:ranges]
# # #   plan.position  = attrs[:position]
# # #   plan.is_active = true
# # #   plan.save!
# # # end

# # # # ─── Seed User for Local Feeds ─────────────────────────────────────────────
# # # seed_user = User.find_or_create_by!(phone_number: "9000000001") do |u|
# # #   u.name         = "Twitter24 Seed"
# # #   u.email        = "seed@twitter24.com"
# # #   u.password     = "Twitter24!"
# # #   u.account_type = "business"
# # #   u.phone_verified = true
# # # end

# # # # ─── 50 Local Feeds (Andhra Pradesh) ───────────────────────────────────────
# # # LOCAL_FEEDS_DATA = [
# # #   { title: "Fresh Fruits Available at Rythu Bazaar", category: "Food & Dining",
# # #     description: "Get fresh seasonal fruits directly from farmers at Rythu Bazaar, Kakinada. Best prices guaranteed every morning from 6 AM to 10 AM.",
# # #     lat: 16.9891, lng: 82.2475, address: "Rythu Bazaar, Kakinada", reach: 5 },

# # #   { title: "Yoga Classes Starting This Sunday", category: "Health & Fitness",
# # #     description: "Join our beginner-friendly yoga sessions at Sai Nagar Community Hall. Classes from 6 AM to 7 AM. Bring your own mat. First session free!",
# # #     lat: 16.9944, lng: 82.2342, address: "Sai Nagar, Kakinada", reach: 8 },

# # #   { title: "Power Cut Alert - Rajam Nagar", category: "Alerts & Notices",
# # #     description: "Scheduled maintenance power cut on Thursday from 9 AM to 5 PM in Rajam Nagar area. Please store water and charge devices in advance.",
# # #     lat: 16.9820, lng: 82.2561, address: "Rajam Nagar, Kakinada", reach: 3 },

# # #   { title: "Used Furniture Sale - Moving Out", category: "Buy & Sell",
# # #     description: "Selling wooden dining table (6 seater), 2 wardrobes, and a sofa set. Good condition. Priced at 60% of original. Contact before Sunday.",
# # #     lat: 16.9765, lng: 82.2398, address: "Surya Rao Peta, Kakinada", reach: 10 },

# # #   { title: "Blood Donation Camp at District Hospital", category: "Community",
# # #     description: "Voluntary blood donation camp organized by Lions Club on 15th. All blood groups needed. Donors will receive free health check-up and refreshments.",
# # #     lat: 16.9805, lng: 82.2497, address: "District Hospital Road, Kakinada", reach: 20 },

# # #   { title: "New Bakery Opening in Ramaraopeta", category: "Food & Dining",
# # #     description: "Suresh Bakery now open! Fresh bread, pastries, and Andhra-style snacks daily. Special inaugural offer — buy 2 get 1 free on all items this week.",
# # #     lat: 17.0012, lng: 82.2380, address: "Ramaraopeta, Kakinada", reach: 6 },

# # #   { title: "Tuition Classes for 10th Students", category: "Education",
# # #     description: "Experienced teacher offering tuition for Maths and Science for Class 10 students. Batch size limited to 10. Telugu and English medium both available.",
# # #     lat: 16.9878, lng: 82.2521, address: "JNT Colony, Kakinada", reach: 7 },

# # #   { title: "Stray Dog Menace Near Bus Stand", category: "Alerts & Notices",
# # #     description: "Stray dog bites reported near Old Bus Stand. Citizens advised to be careful in the evening. Animal welfare committee has been notified.",
# # #     lat: 16.9834, lng: 82.2444, address: "Old Bus Stand Area, Kakinada", reach: 4 },

# # #   { title: "Weekend Cricket Tournament - Register Now", category: "Sports & Events",
# # #     description: "Open cricket tournament this weekend at Municipal Grounds. Teams of 11. Entry fee ₹500 per team. Cash prize for winners. Register by Friday.",
# # #     lat: 16.9921, lng: 82.2312, address: "Municipal Grounds, Kakinada", reach: 15 },

# # #   { title: "Auto Repair Shop Now Open 24/7", category: "Services",
# # #     description: "Prasad Auto Works at Main Road is now open round the clock. Specializing in two-wheelers. Quick service, genuine parts. Emergency breakdown support available.",
# # #     lat: 16.9856, lng: 82.2478, address: "Main Road, Kakinada", reach: 12 },

# # #   { title: "Vizag Beach Cleanup Drive This Sunday", category: "Community",
# # #     description: "Join us for a beach cleanup drive at Ramakrishna Beach. Bring gloves and bags. Organized by Green Earth NGO. Refreshments provided. All are welcome.",
# # #     lat: 17.7231, lng: 83.3012, address: "Ramakrishna Beach, Visakhapatnam", reach: 10 },

# # #   { title: "Biryani Festival at Jagadamba Junction", category: "Food & Dining",
# # #     description: "3-day Biryani Festival featuring 15 varieties from across Andhra. Live cooking demos, tasting sessions, and discounts on bulk orders. Don't miss it!",
# # #     lat: 17.7156, lng: 83.3040, address: "Jagadamba Junction, Visakhapatnam", reach: 25 },

# # #   { title: "House for Rent - Seethammadhara", category: "Real Estate",
# # #     description: "2BHK house available for rent at ₹12,000/month. Ground floor, 24-hr water, covered parking. Vegetarians preferred. Available from 1st of next month.",
# # #     lat: 17.7289, lng: 83.3178, address: "Seethammadhara, Visakhapatnam", reach: 8 },

# # #   { title: "IT Job Fair at GITAM Campus", category: "Jobs",
# # #     description: "Campus job fair open to all graduates. Companies including TCS, Infosys, and HCL participating. Carry 2 copies of resume and govt ID. Entry free.",
# # #     lat: 17.7325, lng: 83.3345, address: "GITAM University, Visakhapatnam", reach: 30 },

# # #   { title: "Lost Dog - Please Help Find", category: "Alerts & Notices",
# # #     description: "Lost golden retriever named 'Tommy' near MVP Colony. Friendly, wears blue collar. Reward for safe return. Please call if spotted.",
# # #     lat: 17.7198, lng: 83.3289, address: "MVP Colony, Visakhapatnam", reach: 10 },

# # #   { title: "Carnatic Music Workshop for Beginners", category: "Education",
# # #     description: "Free Carnatic music workshop every Saturday at Kalabhavan. Open to all age groups. Instruments provided. Conducted by Vidvan Subrahmanyam Garu.",
# # #     lat: 17.6897, lng: 83.2178, address: "Kalabhavan, Visakhapatnam", reach: 20 },

# # #   { title: "Flood Warning - Low-lying Areas Rajahmundry", category: "Alerts & Notices",
# # #     description: "Godavari water level rising. Residents in low-lying areas near Pushkar Ghats are advised to move to safer locations. Municipal helpline: 0883-2464321.",
# # #     lat: 17.0005, lng: 81.8040, address: "Pushkar Ghats, Rajahmundry", reach: 15 },

# # #   { title: "Antique Book Fair at Rajahmundry Town Hall", category: "Shopping",
# # #     description: "Rare Telugu literature, old magazines, and antique books available at throwaway prices. Come explore 500+ titles. Open 9 AM to 8 PM this weekend.",
# # #     lat: 17.0045, lng: 81.7963, address: "Town Hall, Rajahmundry", reach: 12 },

# # #   { title: "Homemade Pickles and Papads - Order Now", category: "Food & Dining",
# # #     description: "Traditional Andhra avakaya, tomato pickle, gongura pickle and more. Made fresh with no preservatives. Home delivery available in Rajahmundry city limits.",
# # #     lat: 16.9988, lng: 81.7891, address: "Innespeta, Rajahmundry", reach: 8 },

# # #   { title: "Plumber Available - Immediate Service", category: "Services",
# # #     description: "Experienced plumber available for all kinds of plumbing work — pipe fitting, bathroom renovation, motor installation. Call for free inspection today.",
# # #     lat: 17.0021, lng: 81.8012, address: "Venkatanarayana Road, Rajahmundry", reach: 6 },

# # #   { title: "Government School Scholarship Applications Open", category: "Education",
# # #     description: "SC/ST/BC students studying in Classes 6-10 can apply for state scholarship. Last date this Friday. Visit school headmaster or MEO office for forms.",
# # #     lat: 15.8281, lng: 78.0373, address: "Kurnool Town, Kurnool", reach: 20 },

# # #   { title: "Wholesale Onion and Potato Market", category: "Buy & Sell",
# # #     description: "Direct from farmers — fresh onions ₹18/kg, potatoes ₹22/kg. Bulk orders of 10kg+ get 5% discount. Available at Agricultural Market Yard every day.",
# # #     lat: 15.8345, lng: 78.0521, address: "Agricultural Market Yard, Kurnool", reach: 10 },

# # #   { title: "Free Eye Camp at Lions Club", category: "Health & Fitness",
# # #     description: "Free eye check-up and spectacles distribution camp for senior citizens. Organized by Kurnool Lions Club. Bring your Aadhaar card. Sunday 9 AM to 2 PM.",
# # #     lat: 15.8267, lng: 78.0412, address: "Lions Club Hall, Kurnool", reach: 15 },

# # #   { title: "New Water Supply Pipe Work - Road Closed", category: "Alerts & Notices",
# # #     description: "APSPDCL road widening and water pipeline work on Hospital Road causing traffic diversion. Expected to complete in 5 days. Use alternate routes.",
# # #     lat: 15.8312, lng: 78.0489, address: "Hospital Road, Kurnool", reach: 5 },

# # #   { title: "Ladies Self Defense Workshop", category: "Health & Fitness",
# # #     description: "Free self-defense training for women and girls above 14 years. Conducted by trained instructors from Police department. Saturday and Sunday, 4 PM to 6 PM.",
# # #     lat: 15.8290, lng: 78.0561, address: "Women's College Ground, Kurnool", reach: 12 },

# # #   { title: "Traditional Handloom Sarees - Direct from Weavers", category: "Shopping",
# # #     description: "Authentic Mangalagiri and Pochampally handloom sarees at weaver prices. No middleman. Quality guaranteed. Home delivery available.",
# # #     lat: 16.4307, lng: 80.5497, address: "Mangalagiri, Guntur", reach: 20 },

# # #   { title: "Guntur Mirchi Wholesale Available", category: "Buy & Sell",
# # #     description: "Premium Guntur red chilli (LCA334 variety) available in bulk. ₹150/kg for 50kg+. Contact for farm-fresh stock. Delivery arranged.",
# # #     lat: 16.3067, lng: 80.4365, address: "Mirchi Yard, Guntur", reach: 30 },

# # #   { title: "Painting Classes for Kids This Summer", category: "Education",
# # #     description: "Watercolor, sketching, and craft workshops for kids aged 5-15. Morning and evening batches. 20-day course at ₹800 only. Limited seats available.",
# # #     lat: 16.3245, lng: 80.4512, address: "Brodipet, Guntur", reach: 10 },

# # #   { title: "Auto Stands Blockade - Plan Your Route", category: "Alerts & Notices",
# # #     description: "Auto union strike called tomorrow. Services will be unavailable from 6 AM to 6 PM. Citizens advised to use APSRTC buses or pool rides.",
# # #     lat: 16.3098, lng: 80.4398, address: "Guntur Bus Stand, Guntur", reach: 15 },

# # #   { title: "Night Bazaar at Collectorate Ground", category: "Shopping",
# # #     description: "Night market with 80+ stalls — street food, clothes, electronics, handicrafts. Open 6 PM to 11 PM this Saturday and Sunday. Entry free.",
# # #     lat: 16.3156, lng: 80.4321, address: "Collectorate Ground, Guntur", reach: 18 },

# # #   { title: "Tirupati Darshan Tickets Available", category: "Travel & Tourism",
# # #     description: "TTD special entry darshan tickets available for next month. Group bookings accepted. Contact Srinivas Travels, Beside Balaji Temple, Nellore.",
# # #     lat: 14.4426, lng: 79.9865, address: "Balaji Temple Road, Nellore", reach: 25 },

# # #   { title: "Prawns and Fish Fresh Stock Today", category: "Food & Dining",
# # #     description: "Fresh catch from Pulicat Lake. Tiger prawns, Rohu, Catla and Pomfret available. Home delivery in Nellore city before 11 AM daily.",
# # #     lat: 14.4534, lng: 79.9912, address: "Fish Market, Nellore", reach: 8 },

# # #   { title: "House Painting Work at Low Cost", category: "Services",
# # #     description: "Interior and exterior painting with quality Asian Paints at ₹8/sq.ft labour only. Free colour consultation. Experienced team of 5 painters.",
# # #     lat: 14.4389, lng: 79.9834, address: "Grand Trunk Road, Nellore", reach: 12 },

# # #   { title: "River Cauvery Flooding Alert", category: "Alerts & Notices",
# # #     description: "Heavy rains causing river levels to rise. People near Srirangapatna ghats advised to stay away. NDRF teams deployed. Updates from district collector's office.",
# # #     lat: 14.4312, lng: 79.9756, address: "Nellore District", reach: 40 },

# # #   { title: "Zumba Dance Fitness Batch Starting", category: "Health & Fitness",
# # #     description: "New batch starting Monday. Morning (6 AM) and evening (6 PM) sessions. Suitable for all fitness levels. Trial class free. Join before Sunday to get 10% off.",
# # #     lat: 14.4467, lng: 79.9989, address: "Pogathota, Nellore", reach: 6 },

# # #   { title: "Old Gold and Silver Buyers - Best Rates", category: "Services",
# # #     description: "We buy old gold and silver jewellery at best market rates. Instant payment. No hidden charges. Trustworthy family business since 1988. Open all days.",
# # #     lat: 13.6288, lng: 79.4192, address: "Gandhi Road, Tirupati", reach: 10 },

# # #   { title: "Accommodation Near Tirumala Available", category: "Real Estate",
# # #     description: "Clean and affordable rooms for pilgrims near Tirumala road. ₹600 per night. AC and non-AC options. Booking open for next 30 days.",
# # #     lat: 13.6345, lng: 79.4234, address: "Tirumala Road, Tirupati", reach: 8 },

# # #   { title: "Prasadam Distribution at Balaji Mandir", category: "Community",
# # #     description: "Free Annadanam (meal) every Sunday at Sri Balaji Mandir. Open for all devotees. Timings: 12 PM to 3 PM. Donations welcome but not mandatory.",
# # #     lat: 13.6198, lng: 79.4123, address: "Sri Balaji Mandir, Tirupati", reach: 5 },

# # #   { title: "Mobile Phone Repair - All Brands", category: "Services",
# # #     description: "Screen replacement, battery change, charging port fix — all done within 1 hour. 3-month warranty on all repairs. Free diagnosis. Walk-in or call ahead.",
# # #     lat: 13.6312, lng: 79.4178, address: "TP Area, Tirupati", reach: 6 },

# # #   { title: "Second Hand Books Stall - Near RTC Bus Stand", category: "Shopping",
# # #     description: "Engineering, degree, and school textbooks at 50% off. Exchange your old books and get credit for new ones. Open daily 9 AM to 7 PM.",
# # #     lat: 13.6256, lng: 79.4156, address: "RTC Bus Stand, Tirupati", reach: 8 },

# # #   { title: "Free Skill Development Workshop for Youth", category: "Education",
# # #     description: "AP government's free skill training in computer basics, spoken English, and personality development. 30-day course. Certificate provided. Seats limited.",
# # #     lat: 14.9091, lng: 79.9899, address: "APSSDC Center, Ongole", reach: 20 },

# # #   { title: "Crab and Lobster Available - Bulk Orders", category: "Food & Dining",
# # #     description: "Fresh crabs and lobsters from local fishermen. Bulk order of 5kg+ gets free home delivery in Ongole. Order before 7 AM for same-day delivery.",
# # #     lat: 15.5057, lng: 80.0499, address: "Harbour, Ongole", reach: 15 },

# # #   { title: "Power Loom Workers Needed Urgently", category: "Jobs",
# # #     description: "Textile company near Chirala seeking experienced power loom operators. ₹15,000-18,000/month. Accommodation provided. Contact HR on weekdays.",
# # #     lat: 15.8161, lng: 80.3524, address: "Chirala, Prakasam", reach: 20 },

# # #   { title: "Road Pothole Complaint - Ward 12", category: "Community",
# # #     description: "Multiple potholes on Collector office road near Ward 12. Vehicles getting damaged. Citizens urge municipality to take immediate action. Photos submitted.",
# # #     lat: 16.9174, lng: 81.6966, address: "Ward 12, Eluru", reach: 5 },

# # #   { title: "Cycle Rickshaw Festival Parade", category: "Sports & Events",
# # #     description: "Annual cycle and rickshaw parade for Independence Day celebrations. Participation open to all. Register at Municipal Office before Friday. Prizes for all.",
# # #     lat: 16.7107, lng: 81.0952, address: "Town Park, Bhimavaram", reach: 10 },

# # #   { title: "Mango Varieties Direct from Orchard", category: "Food & Dining",
# # #     description: "Banganapalle, Totapuri, Himayat and Rasaalu mangoes direct from Nunna farm. Order 5kg+ for free delivery within Vijayawada. This week's stock limited.",
# # #     lat: 16.5062, lng: 80.6480, address: "Nunna, Vijayawada", reach: 15 },

# # #   { title: "Laptop Servicing at Home - Call Us", category: "Services",
# # #     description: "Doorstep laptop repair — virus removal, RAM/SSD upgrade, OS install, keyboard replacement. All brands. Charges start from ₹200. Same-day service.",
# # #     lat: 16.5193, lng: 80.6305, address: "Governorpet, Vijayawada", reach: 10 },

# # #   { title: "Upcoming Kuchipudi Dance Performance", category: "Sports & Events",
# # #     description: "Classical Kuchipudi dance recital by students of Natya Sudha Institute this Saturday at Tummalapalli Kalakshetram. Tickets ₹50 at door. All are welcome.",
# # #     lat: 16.5145, lng: 80.6178, address: "Kalakshetram, Vijayawada", reach: 25 },

# # #   { title: "Bore Water Problem - Residents Suffering", category: "Community",
# # #     description: "Bore water in Krishna Lanka area showing yellow color and bad odor for last 3 days. Health risk to children. Residents requesting immediate municipal action.",
# # #     lat: 16.5089, lng: 80.6234, address: "Krishna Lanka, Vijayawada", reach: 4 },

# # #   { title: "Tailor Available for Home Stitching", category: "Services",
# # #     description: "Experienced tailor offering home visits for blouse, salwar, and kids' clothing stitching. Bridal stitching available. Rates start ₹150 per piece.",
# # #     lat: 16.5234, lng: 80.6412, address: "Patamata, Vijayawada", reach: 7 },
# # # ].freeze

# # # puts "Seeding 50 local feeds..."

# # # LOCAL_FEEDS_DATA.each_with_index do |feed_data, i|
# # #   GlobalFeed.find_or_create_by!(
# # #     title:   feed_data[:title],
# # #     user_id: seed_user.id
# # #   ) do |f|
# # #     f.description    = feed_data[:description]
# # #     f.category       = feed_data[:category]
# # #     f.feed_type      = "local"
# # #     f.latitude       = feed_data[:lat]
# # #     f.longitude      = feed_data[:lng]
# # #     f.address        = feed_data[:address]
# # #     f.reach_distance = feed_data[:reach]
# # #     f.tags           = []
# # #     f.links          = []
# # #     f.created_at     = Time.now - (50 - i).hours
# # #   end
# # # end

# # # puts "✓ 50 local feeds seeded."
# ─── Dynamic Categories Seeding ────────────────────────────────────────────────


categories_data = [
  { priority: 1, name: 'Emergency Services', emoji: '🚨', is_active: true },
  { priority: 2, name: 'Food & Dining', emoji: '🍽️', is_active: true },
  { priority: 3, name: 'Healthcare', emoji: '🏥', is_active: true },
  { priority: 4, name: 'Daily Needs', emoji: '🛒', is_active: true },
  { priority: 5, name: 'Home Services', emoji: '🏠', is_active: true },
  { priority: 6, name: 'Public Services', emoji: '🏛️', is_active: true },
  { priority: 8, name: 'Real Estate', emoji: '🏘️', is_active: true },
  { priority: 9, name: 'Transportation & Travel', emoji: '🚗', is_active: true },
  { priority: 10, name: 'Events & Venues', emoji: '🎉', is_active: true },
  { priority: 11, name: 'Education', emoji: '🎓', is_active: true },
  { priority: 12, name: 'Learning & Skills', emoji: '📚', is_active: true },
  { priority: 13, name: 'Tech Services', emoji: '💻', is_active: true },
  { priority: 14, name: 'Local Marketplace', emoji: '🛍️', is_active: true },
  { priority: 15, name: 'Sports & Fitness', emoji: '🏋️', is_active: true },
  { priority: 16, name: 'Beauty & Personal Care', emoji: '💄', is_active: true },
  { priority: 17, name: 'Fashion', emoji: '👕', is_active: true },
  { priority: 18, name: 'Tailors & Designers', emoji: '✂️', is_active: true },
  { priority: 19, name: 'Nutrition & Wellness', emoji: '🥗', is_active: true },
  { priority: 20, name: 'Pet Care', emoji: '🐾', is_active: true },
  { priority: 21, name: 'Experts & Consultants', emoji: '👨💼', is_active: true },
  { priority: 22, name: 'Hotels & Resorts', emoji: '🏨', is_active: true },
  { priority: 23, name: 'Cloud Kitchens', emoji: '🍲', is_active: true },
  { priority: 24, name: 'Snack Spots & Street Food', emoji: '🌮', is_active: true },
  { priority: 25, name: 'Franchise Opportunities', emoji: '🤝', is_active: true },
  { priority: 26, name: 'Tourism & Explore', emoji: '🧭', is_active: true },
  { priority: 27, name: 'Heritage & Culture', emoji: '🏺', is_active: true },
  { priority: 28, name: 'Religious Places', emoji: '🛕', is_active: true },
  { priority: 29, name: 'Government & Political Offices', emoji: '🏢', is_active: true },
  { priority: 30, name: 'Local Community Groups', emoji: '👥', is_active: true }
]

categories_data.each do |cat|
  Category.find_or_create_by!(name: cat[:name]) do |category|
    category.priority = cat[:priority]
    category.emoji = cat[:emoji]
    category.is_active = cat[:is_active]
  end
end

puts "Seeded \#{Category.count} categories!"