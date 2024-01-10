# frozen_string_literal: true

module Bp3
  module FriendlyId
    if defined?(Rails.env)
      class Railtie < Rails::Railtie
        initializer 'bp3.friendly_id.railtie.register' do |app|
          app.config.after_initialize do
            ::FriendlyId::Slug # preload
            module ::FriendlyId
              class Slug
                include Bp3::Core::Rqid
                include Bp3::Core::Sqnr
                include Bp3::Core::Tenantable
                include Bp3::Core::Displayable
                include Bp3::Core::Ransackable

                configure_tenancy
                use_sqnr_for_ordering
                has_paper_trail

                # TODO: configure GRS and method. use mattr accessors ?
                scope :current_site, -> { where(sites_site_id: GRS.current_site_id) }

                def self.table_name_basis
                  table_name.gsub(/\Apublic\./, '').singularize
                end

                def self.find(id_or_slug)
                  where(id: id_or_slug).or(where(slug: id_or_slug)).first
                end

                def url
                  return nil if slug.blank?
                  return "#{sluggable.site.url}#{slug}" unless draft?

                  # slug is supposed to start with '/'
                  "#{sluggable.site.url}#{slug}?preview=on&id=#{sluggable.id}"
                end

                def display_name
                  slug
                end

                private

                def version_filter_mask
                  '[FILTERED][FR]'
                end

                def draft?
                  sluggable.draft?
                end

                # override Tenantable method to use the sluggable's site, if it *is* a site, or
                # if it *has* a site
                def set_sites_site_id
                  return if sluggable_type.blank?

                  self.sites_site_id = if sluggable.is_a?(Sites::Site)
                                         sluggable.id
                                       elsif sluggable.respond_to?(:sites_site_id)
                                         sluggable.sites_site_id
                                       end
                  return if sites_site_id.present?

                  super
                end
              end
            end
          end
        end
      end
    end
  end
end
