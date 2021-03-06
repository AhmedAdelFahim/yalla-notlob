class OrdersController < ApplicationController
  # include Pagy::Backend
  before_action :auth
  before_action :set_order, only: [:show, :edit, :update, :destroy]
  respond_to :json, :html, :js

  def auth
    if ! current_user
      redirect_to new_user_session_path, notice: 'You are not logged in.'
    end
  end

  # GET /orders
  # GET /orders.json
  def index
    if current_user
      #User.find(current_user.id).orders.to_a +
      @pagy, @orders = pagy_array(Order.find_by_sql("SELECT order_type,restaurant,joined_num ,invited_num,status, orders.user_id, orders.id from orders, user_join_orders WHERE orders.id = user_join_orders.order_id AND user_join_orders.user_id = #{current_user.id}"),items: 2)
    else
      redirect_to new_user_session_path, notice: 'You are not logged in.'
    end
  end

  # GET /orders/1
  # GET /orders/1.json
  def show
  end

  # GET /orders/new
  def new
    @order = Order.new
  end

  # GET /orders/1/edit
  def edit
  end

  # POST /orders
  # POST /orders.json
  def create
    p " user id : #{current_user.id}"
    @order = Order.new
    @order.order_type = params[:order_type]
    @order.restaurant = params[:restaurant]
    @order.menu_img = params[:menu_img]
    @order.status =  "waiting"
    @order.invited_num = 0
    @order.user_id = current_user.id
    if @order.save()
      invitedFriends = params[:invited].split(',');
      saveInUserInvitedToOrder(invitedFriends);
      saveInUserJoinOrder();
    end
    redirect_to action: :index
  end
  
  
  def checkInvitedExistance
    @userGroups = User.find(current_user.id).groups
    
    @users = User.where(email: params[:keyword]);
      if @users.length != 0
        status = "true"
        respond_with(@users, :include => :status)
      else
        @users = Group.where(name: params[:keyword])
          if @users.length != 0
            flag = 0
            @users.each do |group|
              if @userGroups.ids.include? group.id or group.user_id === current_user.id
                flag = 1
                result = true
                respond_with(@users, :include => :status)
              end
            end
            if flag == 0
              @users = nil
              respond_with(@users, :include => :status) 
            end
          else
            @users = nil
            respond_with(@users, :include => :status)
          end
      end
  end
  
  def saveInUserInvitedToOrder(invitedFriends)
    invited_num = 0
    invitedFriends.each do |invited|
      @user = User.where(name: invited);
      if @user.length != 0
          guest_id = @user.first.id
          InUserInvitedToOrderData(guest_id)
          invited_num = invited_num + 1 
      else
          @users = Group.find_by(name: invited).users;
          if @users.length != 0
            @users.each do |user|
              if user.id != current_user.id
                guest_id = user.id
                InUserInvitedToOrderData(guest_id)
                invited_num = invited_num + 1 
              end
            end
          else
              p "this is not match friend or group";
          end
      end
    end
    updateInvitedNum(invited_num);
  end


  def InUserInvitedToOrderData(guest_id)
    @lastOrder = Order.where(user_id: current_user.id).order("created_at DESC").first;
    @userInvitedToOrder = UserInvitedToOrder.new
    @userInvitedToOrder.order_id = @lastOrder.id;
    @userInvitedToOrder.host_id = current_user.id;
    @userInvitedToOrder.guest_id = guest_id;
    @userInvitedToOrder.status = "pending"
    @userInvitedToOrder.save();
  end

  def saveInUserJoinOrder()
    @lastOrder = Order.where(user_id: current_user.id).order("created_at DESC").first;
    @userJoinOrder = UserJoinOrder.new
    @userJoinOrder.order_id = @lastOrder.id;
    @userJoinOrder.user_id = current_user.id;
    @userJoinOrder.save();
  end

  def updateInvitedNum(invited_num)
    @lastOrder = Order.where(user_id: current_user.id).order("created_at DESC").first;
    Order.update(@lastOrder.id, :invited_num => invited_num)
  end

  # PATCH/PUT /orders/1
  # PATCH/PUT /orders/1.json
  def update
    respond_to do |format|
      if @order.update(order_params)
        format.html { redirect_to @order, notice: 'Order was successfully updated.' }
        format.json { render :show, status: :ok, location: @order }
      else
        format.html { render :edit }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1
  # DELETE /orders/1.json
  def destroy
    @order.destroy
    respond_to do |format|
      format.html { redirect_to orders_url, notice: 'Order was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def updateStatus
    # order = User.find(current_user.id).orders.where(id: params[:orderId]);
    # p order.update(status: params[:status])
    st = ActiveRecord::Base.connection.raw_connection.prepare("UPDATE `orders` SET `orders`.`status` = ?, `orders`.`updated_at` = ? WHERE `orders`.`id` = ?")
    st.execute(params[:status]  , DateTime.now, params[:orderId])
    st.close
    redirect_to orders_url
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order
      @order = Order.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def order_params
      params.fetch(:order, {})
    end
end
