module BusinessAuthorized
  extend ActiveSupport::Concern

  # Halts with 403 if the requester is not a business account.
  # Returns true on success so callers can chain:
  #   return unless require_business!
  def require_business!
    return true if current_user.account_type == "business"

    render json: {
      error:                   "Only business accounts are allowed to perform this action.",
      account_type_required:   "business",
      current_account_type:    current_user.account_type
    }, status: :forbidden
    false
  end
end
