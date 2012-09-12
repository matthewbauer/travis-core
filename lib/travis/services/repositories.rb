module Travis
  module Services
    class Repositories
      def find_all(params)
        scope = model.timeline.recent
        scope = scope.by_member(params[:member])         if params[:member]
        scope = scope.by_owner_name(params[:owner_name]) if params[:owner_name]
        scope = scope.by_owner_name(params[:login])      if params[:login]
        scope = scope.by_slug(params[:slug])             if params[:slug]
        scope = scope.search(params[:search])            if params[:search].present?
        scope
      end

      def find_one(params)
        model.find_by(params)
      end

      def find_or_create_by(params)
        find_one(params) || Repository.create!(params.slice(:owner_name, :name))
      end

      private

        def model
          Repository
        end
    end
  end
end
