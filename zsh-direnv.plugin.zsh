#!/usr/bin/env zsh

#####################
# COMMONS
#####################

#########################
# PLUGIN MAIN
#########################

ZSH_DIRENV_BIN_DIR="$HOME/.local/bin"
ZSH_DIRENV_BIN_PATH="$ZSH_DIRENV_BIN_DIR/direnv"

#########################
# Functions
#########################

_zsh_direnv_log() {
  local msg=$1
  echo "[zsh-direnv-plugin] $msg"
}

_zsh_direnv_last_version() {
  curl -s https://api.github.com/repos/direnv/direnv/releases/latest | grep tag_name | cut -d '"' -f 4
}

_zsh_direnv_install_if_missing() {
  if command -v direnv >/dev/null 2>&1; then
    return 0
  fi

  if [[ -x "$ZSH_DIRENV_BIN_PATH" ]]; then
    return 0
  fi

  _zsh_direnv_log "#############################################"
  _zsh_direnv_log "Installing direnv to ${ZSH_DIRENV_BIN_PATH}..."

  if ! command -v curl >/dev/null 2>&1; then
    _zsh_direnv_log "curl not found; cannot auto-install direnv"
    _zsh_direnv_log "#############################################"
    return 1
  fi

  mkdir -p "$ZSH_DIRENV_BIN_DIR" || {
    _zsh_direnv_log "Failed to create directory: ${ZSH_DIRENV_BIN_DIR}"
    _zsh_direnv_log "#############################################"
    return 1
  }

  local version="$(_zsh_direnv_last_version)"
  if [[ -z "$version" ]]; then
    _zsh_direnv_log "Failed to detect latest direnv version"
    _zsh_direnv_log "#############################################"
    return 1
  fi

  local machine
  case "$(uname -m)" in
    x86_64)
      machine=amd64
      ;;
    arm64)
      machine=arm64
      ;;
    aarch64)
      machine=arm64
      ;;
    i686 | i386)
      machine=386
      ;;
    *)
      _zsh_direnv_log "Machine $(uname -m) not supported by this plugin"
      _zsh_direnv_log "#############################################"
      return 1
    ;;
  esac

  local os
  case "$OSTYPE" in
    darwin*) os=darwin ;;
    linux*) os=linux ;;
    *)
      _zsh_direnv_log "OSTYPE ${OSTYPE} not supported by this plugin"
      _zsh_direnv_log "#############################################"
      return 1
    ;;
  esac

  _zsh_direnv_log "  -> download and install direnv ${version}"
  if ! curl -fsSL -o "$ZSH_DIRENV_BIN_PATH" "https://github.com/direnv/direnv/releases/download/${version}/direnv.${os}-${machine}"; then
    _zsh_direnv_log "Failed to download direnv from GitHub releases"
    _zsh_direnv_log "#############################################"
    return 1
  fi

  if ! chmod +x "$ZSH_DIRENV_BIN_PATH"; then
    _zsh_direnv_log "Failed to set executable bit: ${ZSH_DIRENV_BIN_PATH}"
    _zsh_direnv_log "#############################################"
    return 1
  fi

  _zsh_direnv_log "Install OK"
  _zsh_direnv_log "#############################################"
}

_zsh_direnv_load() {
  # export PATH if needed
  if [[ -z ${path[(r)$ZSH_DIRENV_BIN_DIR]} ]]; then
    path+=($ZSH_DIRENV_BIN_DIR)
  fi
    eval "$(direnv hook zsh)"
}

# install direnv if it isn't already installed
_zsh_direnv_install_if_missing

# load direnv if it is installed
if command -v direnv >/dev/null 2>&1 || [[ -x "$ZSH_DIRENV_BIN_PATH" ]]; then
  _zsh_direnv_load
fi

unset -f _zsh_direnv_install_if_missing _zsh_direnv_load _zsh_direnv_last_version
