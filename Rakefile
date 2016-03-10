# need to add this path for stand-alone migrations that use models

require 'rake'
require 'rspec/core/rake_task'
require 'bundler/setup'
require 'micro_migrations'
require 'travis/migrations'
require 'travis'

ActiveRecord::Base.schema_format = :sql

task :default => :spec

ActiveRecord::Base.schema_format = :sql

namespace :db do
  if ENV["RAILS_ENV"] == 'test'
    desc 'Create and migrate the test database'
    task :create do
      sh 'createdb travis_test' rescue nil
      sh "psql -q travis_test < #{Gem.loaded_specs['travis-migrations'].full_gem_path}/db/structure.sql"
    end
  else
    desc 'Create and migrate the development database'
    task :create do
      sh 'createdb travis_development' rescue nil
      sh "psql -q travis_development < #{Gem.loaded_specs['travis-migrations'].full_gem_path}/db/structure.sql"
    end
  end
end

desc 'Run specs'
RSpec::Core::RakeTask.new do |t|
  t.pattern = './spec/**/*_spec.rb'
end
begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new
  task default: :spec
rescue LoadError
  warn "could not load rspec"
end


module ActiveRecord
  class Migration
    class << self
      attr_accessor :disable_ddl_transaction
    end

    # Disable DDL transactions for this migration.
    def self.disable_ddl_transaction!
      @disable_ddl_transaction = true
    end

    def disable_ddl_transaction # :nodoc:
      self.class.disable_ddl_transaction
    end
  end

  class Migrator
    def use_transaction?(migration)
      !migration.disable_ddl_transaction && Base.connection.supports_ddl_transactions?
    end

    def ddl_transaction(migration, &block)
      if use_transaction?(migration)
        Base.transaction { block.call }
      else
        block.call
      end
    end

    def migrate(&block)
      current = migrations.detect { |m| m.version == current_version }
      target = migrations.detect { |m| m.version == @target_version }

      if target.nil? && @target_version && @target_version > 0
        raise UnknownMigrationVersionError.new(@target_version)
      end

      start = up? ? 0 : (migrations.index(current) || 0)
      finish = migrations.index(target) || migrations.size - 1
      runnable = migrations[start..finish]

      # skip the last migration if we're headed down, but not ALL the way down
      runnable.pop if down? && target

      ran = []
      runnable.each do |migration|
        if block && !block.call(migration)
          next
        end

        Base.logger.info "Migrating to #{migration.name} (#{migration.version})" if Base.logger

        seen = migrated.include?(migration.version.to_i)

        # On our way up, we skip migrating the ones we've already migrated
        next if up? && seen

        # On our way down, we skip reverting the ones we've never migrated
        if down? && !seen
          migration.announce 'never migrated, skipping'; migration.write
          next
        end

        begin
          ddl_transaction(migration) do
            migration.migrate(@direction)
            record_version_state_after_migrating(migration.version)
          end
          ran << migration
        rescue => e
          canceled_msg = Base.connection.supports_ddl_transactions? ? "this and " : ""
          raise StandardError, "An error has occurred, #{canceled_msg}all later migrations canceled:\n\n#{e}", e.backtrace
        end
      end
      ran
    end
  end

  class MigrationProxy
    delegate :disable_ddl_transaction, to: :migration
  end
end
