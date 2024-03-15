# php81-fpm

A PHP 8.1 (FPM) based Docker base image.

[![Build Images](https://github.com/Ilyes512/php81-fpm/actions/workflows/main.yml/badge.svg)](https://github.com/Ilyes512/php81-fpm/actions/workflows/main.yml)

NOTE:  
This is replaced by <https://github.com/Ilyes512/php81> which contains both a FPM and a Apache based version.

## Pulling the images

```
docker pull ghcr.io/ilyes512/php81-fpm:runtime-latest
docker pull ghcr.io/ilyes512/php81-fpm:builder-latest
docker pull ghcr.io/ilyes512/php81-fpm:builder-nodejs-latest
docker pull ghcr.io/ilyes512/php81-fpm:vscode-latest
```

The tag scheme: `{TARGET}-{VERSION}`

- **{TARGET}**: `runtime`, `builder`, `builder_nodejs` or `vscode`
- **{VERSION}**: `latest` or tag i.e. `1.0.0`

## Building the docker image(s)

There are multiple targets:

  - **runtime**: this is for *production*. It does not contain any development tools like Composer and Xdebug.
  - **builder**: this is for *development*. This is based on the runtime-target and it adds Composer, Xdebug etc.
  - **builder_nodejs**: this is for *development*. This is based on the builder-target and it adds NodeJS.
  - **vscode**: this is for *development* using
  [VS Code Remote](https://code.visualstudio.com/docs/remote/remote-overview). This is based on the
  `builder_nodejs`-target and adds some VS Code deps.

Building `runtime`-target:

```
docker build --tag ghcr.io/ilyes512/php81-fpm:runtime-latest --target runtime .
```

Building `builder`-target:

```
docker build --tag ghcr.io/ilyes512/php81-fpm:builder-latest --target builder .
```

Building `builder_nodejs`-target:

```
docker build --tag ghcr.io/ilyes512/php81-fpm:builder-nodejs-latest --target builder_nodejs .
```

Building `vscode`-target:

```
docker build --tag ghcr.io/ilyes512/php81-fpm:vscode-latest --target vscode .
```

## Task commands

Available [Task](https://taskfile.dev/#/) commands:

```
* build:          Build all PHP Docker image targets
* lint:           Apply a Dockerfile linter (https://github.com/hadolint/hadolint)
* shell:          Interactive shell
* act:main:       Run Act with push event on main branch
* act:pr:         Run Act with pull_request event
* act:tag:        Run Act with tag (push) event
```

### Act tasks

[Act](https://github.com/nektos/act) is a tool to run Github Actions locally. Before you can run Act and the
`act:*`-tasks you need to add an `GITHUB_TOKEN`-secret. You can do this by adding the following
Act config file to you users `$HOME`-directory:

File path: `~/.actrc`
```
-s GITHUB_TOKEN=<your_github_token>
```

Replace `<your_github_token>` with a Github personal acces token. You can generate a new token
[here](https://github.com/settings/tokens/new?description=Act) (no scopes
are needed!).

Note: Does not (yet) work for Apple devices using Apple Silicon (i.e. M1).
