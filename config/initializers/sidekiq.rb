require 'awesome_print'
require 'sidekiq'
require 'acpc_backend'

AcpcBackend.load! File.expand_path('../../acpc_backend.yml', __FILE__)
AcpcBackend.configure_middleware
# Want to instantiate one worker upon starting
AcpcBackend::Worker.perform_async(AcpcBackend::MAINTAIN_COMMAND) if Sidekiq.server?
