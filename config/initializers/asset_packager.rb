
require Rails.root.join('lib','asset_packager', 'synthesis', 'asset_package_helper.rb')
require Rails.root.join('lib','asset_packager', 'synthesis', 'asset_package.rb')
ActionView::Base.send :include, Synthesis::AssetPackageHelper
