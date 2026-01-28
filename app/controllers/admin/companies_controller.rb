module Admin
  class CompaniesController < BaseController
    def index
      @companies = Company.all.order(:name)
    end
    
    def show
      @company = Company.find(params[:id])
    end
    
    def new
      @company = Company.new
    end
    
    def create
      @company = Company.new(company_params)
      
      if @company.save
        redirect_to admin_companies_path, notice: 'Company created'
      else
        render :new, status: :unprocessable_entity
      end
    end
    
    def edit
      @company = Company.find(params[:id])
    end
    
    def update
      @company = Company.find(params[:id])
      
      if @company.update(company_params)
        redirect_to admin_companies_path, notice: 'Company updated'
      else
        render :edit, status: :unprocessable_entity
      end
    end
    
    def destroy
      @company = Company.find(params[:id])
      @company.destroy
      redirect_to admin_companies_path, notice: 'Company deleted'
    end
    
    def toggle_active
      @company = Company.find(params[:id])
      @company.update!(is_active: !@company.is_active)
      
      render json: { success: true, is_active: @company.is_active }
    end
    
    private
    
    def company_params
      params.require(:company).permit(:name, :parent_company_id, :is_active)
    end
  end
end
