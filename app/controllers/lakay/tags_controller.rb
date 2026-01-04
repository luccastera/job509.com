module Lakay
  class TagsController < BaseController
    before_action :set_tag, only: [:show, :edit, :update, :destroy, :add_user, :remove_user]

    def index
      @tags = Tag.alphabetical
      @pagy, @tags = pagy(@tags, limit: 25)
    end

    def show
      @users = @tag.users.order(:lastname, :firstname)
      @pagy, @users = pagy(@users, limit: 25)
    end

    def add_user
      user = User.find(params[:user_id])
      @tag.users << user unless @tag.users.include?(user)
      redirect_to lakay_tag_path(@tag), notice: "#{user.full_name} added to tag."
    end

    def remove_user
      user = User.find(params[:user_id])
      @tag.users.delete(user)
      redirect_to lakay_tag_path(@tag), notice: "#{user.full_name} removed from tag."
    end

    def new
      @tag = Tag.new
    end

    def create
      @tag = Tag.new(tag_params)

      if @tag.save
        redirect_to lakay_tags_path, notice: t("flash.created", resource: "Tag")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @tag.update(tag_params)
        redirect_to lakay_tags_path, notice: t("flash.updated", resource: "Tag")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @tag.destroy
      redirect_to lakay_tags_path, notice: t("flash.deleted", resource: "Tag")
    end

    private

    def set_tag
      @tag = Tag.find(params[:id])
    end

    def tag_params
      params.require(:tag).permit(:name, :description, :event_id, :icon)
    end
  end
end
