class Admin::LocalRecordsController < ApplicationController
  before_action :authenticate_iesudoer!

  def index
    @records = LocalRecord.where(ip_address_id: nil).order(:name).order(:rdtype)
  end

  def new
    @record = LocalRecord.new
  end

  def create
    @record = LocalRecord.new(local_record_params)

    if @record.save
      redirect_to admin_local_records_path, notice: 'Create LocalRecord Successfully'
    else
      render :new
    end
  end

  def edit
    @record = LocalRecord.find params[:id]
  end

  def update
    @record = LocalRecord.find params[:id]

    if @record.update_attributes(local_record_params)
      redirect_to admin_local_records_path, notice: 'Update LocalRecord Successfully'
    else
      render :edit
    end
  end

  def destroy
    @record = LocalRecord.find params[:id]
    @record.destroy
    redirect_to admin_local_records_path, notice: 'Delete LocalRecord Successfully'
  end

  private

  def local_record_params
    params.require(:local_record).permit(:name, :rdtype, :rdata, :ttl)
  end
end
