class SquadsController < ApplicationController

  def index
    if params[:my_squads].present?
      @squads = current_user.squads
    else
      @squads = Squad.all
    end
  end

  def create
    squad_params = {
      name: params[:name] || "Untitled Squad",
      description: params[:description] || "No description",
      admin_id: current_user.id
    }
    @squad = Squad.create(squad_params)
    redirect_to @squad
  end

  def show
    @squad = Squad.find(params[:id])
  end

  def destroy
    if @squad.admin_id == current_user.id
      @squad.destroy
    else
      redirect_to root_path, alert: "You are not authorized to destroy this squad"
    end
  end

  private

end
