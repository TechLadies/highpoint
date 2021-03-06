
require "active_support/deprecation"

class Clearance::PasswordsController < Clearance::BaseController
  if respond_to?(:before_action)
    skip_before_action :require_login,
                       only: [:create, :edit, :new, :update],
                       raise: false
    skip_before_action :authorize,
                       only: [:create, :edit, :new, :update],
                       raise: false
    before_action :ensure_existing_user, only: [:update]
  else
    skip_before_action :require_login,
                       only: [:create, :edit, :new, :update],
                       raise: false
    skip_before_action :authorize,
                       only: [:create, :edit, :new, :update],
                       raise: false
    before_action :ensure_existing_user, only: [:edit, :update]
  end

  def create
    user = find_user_for_create

    if user
      user.forgot_password!
      deliver_email(user)
      render template: "passwords/create"
    else
      flash.now[:error] = "Sorry, we can't find any users with this email. Please try again."
      render template: "passwords/new"
    end
  end

  def edit
    @user = find_user_for_edit

    if params[:token]
      session[:password_reset_token] = params[:token]
      redirect_to url_for
    else
      render template: "passwords/edit"
    end
  end

  def new
    render template: "passwords/new"
  end

  def update
    @user = find_user_for_update

    if @user.update_password password_reset_params
      sign_in @user
      redirect_to url_after_update
      session[:password_reset_token] = nil
    else
      flash_failure_after_update
      render template: "passwords/edit"
    end
  end

  private

  def deliver_email(user)
    mail = ::ClearanceMailer.change_password(user)

    if mail.respond_to?(:deliver_later)
      mail.deliver_later
    else
      mail.deliver
    end
  end

  def password_reset_params
    if params.key? :user
      ActiveSupport::Deprecation.warn %(Since locales functionality was added, accessing params[:user] is no longer supported.)
      params[:user][:password]
    else
      params[:password_reset][:password]
    end
  end

  def find_user_by_id_and_confirmation_token
    user_param = Clearance.configuration.user_id_parameter
    token = session[:password_reset_token] || params[:token]

    Clearance.configuration.user_model
             .find_by id: params[user_param], confirmation_token: token.to_s
  end

  def find_user_for_create
    # rubocop:disable Rails/DynamicFindBy
    Clearance.configuration.user_model
             .find_by_normalized_email(params[:password][:email])
    # rubocop:enable Rails/DynamicFindBy
  end

  def find_user_for_edit
    find_user_by_id_and_confirmation_token
  end

  def find_user_for_update
    find_user_by_id_and_confirmation_token
  end

  def ensure_existing_user
    unless find_user_by_id_and_confirmation_token
      flash_failure_when_forbidden
      render template: "passwords/new"
    end
  end

  def flash_failure_when_forbidden
    flash.now[:notice] = translate(:forbidden,
                                   scope: [:clearance, :controllers, :passwords],
                                   default: t("flashes.failure_when_forbidden"))
  end

  def flash_failure_after_update
    flash.now[:notice] = translate(:blank_password,
                                   scope: [:clearance, :controllers, :passwords],
                                   default: t("flashes.failure_after_update"))
  end

  def url_after_create
    sign_in_url
  end

  def url_after_update
    Clearance.configuration.redirect_url
  end
end
