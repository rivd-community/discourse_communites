# name: Custom Category Creator
# about: Allows certain user groups to create categories and corresponding moderator groups.
# version: 0.1
# author: Your Name
# url: URL to your plugin's repo

enabled_site_setting :custom_category_creator_enabled

after_initialize do
  Discourse::Application.routes.append do
    post "/create-category" => "custom_category#create"
  end

  class ::CustomCategoryController < ::ApplicationController
    def create
      return render json: { error: "Feature disabled." }, status: 403 unless SiteSetting.custom_category_creator_enabled

      allowed_groups = SiteSetting.allowed_groups.split('|')
      unless GroupUser.where(user_id: current_user.id, group: allowed_groups).exists?
        return render json: { error: "You do not have permission to perform this action." }, status: 403
      end

      group_name = "#{params[:name]}_moderators"
      category = Category.create!(name: params[:name])
      group = Group.create!(name: group_name)

      group.users << current_user
      category.custom_fields["moderators_group_id"] = group.id
      category.save!

      render json: success_json
    rescue => e
      render json: { error: e.message }, status: 422
    end
  end
end

// assets/javascripts/discourse/initializers/custom-category-creator.js
import { withPluginApi } from 'discourse/lib/plugin-api';

function initializeCustomCategoryCreator(api) {
    api.addRoute({
        name: 'create-category',
        path: '/create-category',
        component: 'create-category-form'
    });

    api.modifyClass('route:application', {
        actions: {
            createCategory() {
                this.transitionTo('create-category');
            }
        }
    });
}

export default {
    name: 'custom-category-creator',
    initialize() {
        withPluginApi('0.8.31', initializeCustomCategoryCreator);
    }
};
