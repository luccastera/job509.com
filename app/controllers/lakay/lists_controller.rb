module Lakay
  class ListsController < BaseController
    before_action :set_list, only: [:show, :edit, :update, :destroy, :add_user, :remove_user]

    def index
      @lists = List.alphabetical
      @pagy, @lists = pagy(@lists, limit: 25)
    end

    def show
      @users = @list.users.order(:lastname, :firstname)
      @pagy, @users = pagy(@users, limit: 25)
    end

    def new
      @list = List.new
    end

    def create
      @list = List.new(list_params)

      if @list.save
        redirect_to lakay_list_path(@list), notice: t("flash.created", resource: "List")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @list.update(list_params)
        redirect_to lakay_list_path(@list), notice: t("flash.updated", resource: "List")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @list.destroy
      redirect_to lakay_lists_path, notice: t("flash.deleted", resource: "List")
    end

    def add_user
      user = User.find(params[:user_id])
      @list.users << user unless @list.users.include?(user)
      redirect_to lakay_list_path(@list), notice: "#{user.full_name} added to list."
    end

    def remove_user
      user = User.find(params[:user_id])
      @list.users.delete(user)
      redirect_to lakay_list_path(@list), notice: "#{user.full_name} removed from list."
    end

    private

    def set_list
      @list = List.find(params[:id])
    end

    def list_params
      params.require(:list).permit(:name)
    end
  end
end
