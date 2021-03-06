class UserInvitedToOrdersController < ApplicationController
  before_action :auth

  def auth
    if ! current_user
      redirect_to new_user_session_path, notice: 'You are not logged in.'
    end
  end
  
  def index
    @orders = Order.find(params[:order_id])
    @user_invited_to_order = UserInvitedToOrder.where(order_id:@orders.id)
    p @user_invited_to_order
  end

 

  def destroy
    p "params values: #{params}"

    @user_invited_to_order = UserInvitedToOrder.find(params[:id])
    user_order_id=@user_invited_to_order.order_id
    @user_invited_to_order.destroy
    if @user_invited_to_order.destroy
      flash[:notice] = "User was successfully destroyed."
      redirect_to :controller => "user_invited_to_orders", :action => "index", :order_id => user_order_id
    end



  end
end
