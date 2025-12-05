class ApplicationController < ActionController::Base
  def after_sign_in_path_for(_resource)
    workout_plans_path
  end

  def after_sign_out_path_for(_resource)
    root_path
  end
end
