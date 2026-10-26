# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

bp3-friendly_id adapts `friendly_id` for BP3 (persuavis/black_phoebe_3), a multi-site multi-tenant Rails
application. It makes `FriendlyId::Slug` a tenant-scoped BP3 record that knows its public URL. There is
nothing to configure: adding the gem is enough.

## Commands

The gems run on Ruby 3.4.6 (`.ruby-version`). Prefix commands with `~/.rvm/bin/rvm 3.4.6 do` when the
shell is not already on it; a missing `rspec` means the wrong Ruby, not a missing bundle.

- `bundle exec rake` - specs and RuboCop (the default task)
- `bundle exec rspec spec/path/to/file_spec.rb[:LINE]` - one file or example
- `bundle exec rubocop` / `bundle exec rubocop -a`
- `bin/setup`, `bin/console`, `rake install`

## Architecture

`lib/bp3/friendly_id/railtie.rb` reopens `FriendlyId::Slug` in an `after_initialize` block (only when
`Rails.env` is defined) and:

- includes `Bp3::Core::Rqid`, `Sqnr`, `Tenantable`, `Displayable` and `Ransackable`, calls
  `configure_tenancy`, `use_sqnr_for_ordering` and `has_paper_trail`
- adds `scope :current_site` (the request state's current site) and `table_name_basis`
- replaces `.find` to accept either an id or a slug, returning nil rather than raising
- `url`: the sluggable's `site.url` plus the slug (slugs start with `/`); a draft sluggable gets
  `?preview=on&id=...`. The sluggable must respond to `site` and `draft?`
- `display_name` is the slug; `controllerize` comes from bp3-string; `version_filter_mask` is `'[FILTERED][FR]'`
- overrides `Tenantable#set_sites_site_id` to take the site from the sluggable (the sluggable itself when it
  is a site, else its `sites_site_id`), falling back to the request state

It reaches the request state through `Bp3::Core::Rqid.global_request_state_class` and the site class through
`Bp3::ActionDispatch.site_class`, so it depends on bp3-core, bp3-action_dispatch and bp3-string being
configured.

## Testing

The spec only checks the version; the Railtie needs a Rails application with a database to exercise. Try a
change against the application (black_phoebe_3) by putting this repo's `lib` ahead of the bundled gem.

## Code Style

- RuboCop (`.rubocop.yml`): target Ruby 3.2.2, NewCops, rubocop-rake and rubocop-rspec; AbcSize 26,
  MethodLength 15, BlockLength 66, ModuleLength 150; `Lint/ConstantDefinitionInBlock` and `Lint/Void`
  are off for `lib/bp3/**/railtie.rb`, where classes are reopened inside a block
- Every file starts with `# frozen_string_literal: true`
- American English; no trailing whitespace on any added or modified line

## Release

Bump `lib/bp3/friendly_id/version.rb` and add a `CHANGELOG.md` entry. `rake release` tags, pushes and
publishes to rubygems.org; leave releasing and committing to the user.
