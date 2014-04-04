class UserController < ApplicationController
  def login
    if request.post?
      user = User.find_by_email(params[:email])
      if user && user.authenticate(params[:password])
        redirect_to action: 'dashboard'
      else
        flash[:error] = "An account with that username or password could not be found."
      end
    end
  end

  def signup
    @email = params[:email]
    @password = params[:password]
    @confirm_password = params[:confirm_password]

    if request.post?

      if @password != @confirm_password
        @password = "";
        @confirm_password = "";
        return flash[:error] = "Please ensure the password and password confirmation fields match."
      end

      account = User.new(email: params[:email], password: params[:password])

      if account.valid?
        account.save
        redirect_to action: 'dashboard'
      else
        return @error = 'An account with that email has already been created.'
      end

    end
  end

  def dashboard
  end

end
