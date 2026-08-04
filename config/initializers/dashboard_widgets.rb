# Widget declarations live in app/lib/dashboard/widgets.rb (autoloaded, so
# edits there hot-reload in development). This hook only re-installs them on
# each code reload and should never need to change — initializer files are
# read once at boot and silently ignore edits until a server restart.
Rails.application.config.to_prepare do
  Dashboard::Widgets.install
end
