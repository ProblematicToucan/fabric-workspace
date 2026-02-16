#!/usr/bin/env bash
#
# =============================================================================
# utils.sh — Shared logging and helpers for fabric-workspace scripts
# =============================================================================
#
# Sourced by network.sh and other scripts. Provides:
#   - Colored output: infoln, successln, errorln, warnln, fatalln, println
#   - fatalln prints message and exits with failure
#
# Usage: . scripts/utils.sh  (from fabric-workspace root)
# =============================================================================

# ANSI colors (reset, red, green, blue, yellow)
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_YELLOW='\033[1;33m'

function println() { echo -e "$1"; }
function errorln() { println "${C_RED}${1}${C_RESET}"; }
function successln() { println "${C_GREEN}${1}${C_RESET}"; }
function infoln() { println "${C_BLUE}${1}${C_RESET}"; }
function warnln() { println "${C_YELLOW}${1}${C_RESET}"; }
# Print message in red and exit with failure
function fatalln() { errorln "$1"; exit 1; }

# Export so subshells and sourced scripts can use them
export -f errorln successln infoln warnln fatalln
