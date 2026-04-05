class OnboardingMailer < ApplicationMailer
  default from: ENV.fetch("MAILER_FROM", "twitter24offical@gmail.com")

  def admin_review_notification(user, business)
    @user     = user
    @business = business
    @contact  = business.business_contact
    @location = business.business_location

    mail(
      to:      "twitter24offical@gmail.com",
      subject: "New Business Onboarding Completed — #{business.name} (Review Required)"
    )
  end

  def rejection_notification(user, business)
    @user     = user
    @business = business
    @contact  = business.business_contact

    recipient = @contact&.owner_email.presence ||
                @contact&.contact_email.presence ||
                @user&.email.presence

    return unless recipient.present?

    mail(
      to:      recipient,
      subject: "Your Business Application Was Not Approved — #{business.name}"
    )
  end
end
