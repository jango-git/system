#!/bin/bash

_setup_prompt() {
    # =============================================
    # ANSI COLOR UTILITIES
    # =============================================
    _ansi_color() {
        local type=$1
        local color=$2

        if [[ "$color" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
            local r=$((16#${color:1:2}))
            local g=$((16#${color:3:2}))
            local b=$((16#${color:5:2}))
            echo -n "\[\e[${type};2;${r};${g};${b}m\]"
        elif [[ "$color" =~ ^[0-9]{1,3}$ && "$color" -le 255 ]]; then
            echo -n "\[\e[${type};5;${color}m\]"
        else
            declare -A named_colors=(
                ["default"]="34" ["blue"]="34" ["green"]="32" ["red"]="31" 
                ["yellow"]="33" ["purple"]="35" ["orange"]="208" ["pink"]="205"
            )
            local code="${named_colors[${color}]:-34}"
            echo -n "\[\e[${type};5;${code}m\]"
        fi
    }

    color_to_fg() { _ansi_color "38" "$1"; }
    color_to_bg() { _ansi_color "48" "$1"; }

    # =============================================
    # GNOME ACCENT COLOR DETECTION
    # =============================================
    get_gnome_accent_hex() {
        local accent_color=$(gsettings get org.gnome.desktop.interface accent-color | tr -d "'")
        declare -A color_hex_map=(
            ["default"]="#3584e4" ["blue"]="#3584e4" ["teal"]="#2190a4"
            ["green"]="#33d17a" ["red"]="#e01b24" ["yellow"]="#a37000"
            ["purple"]="#9141ac" ["orange"]="#ff7800" ["pink"]="#e5a0dc"
            ["slate"]="#657482"
        )
        echo -n "${color_hex_map[${accent_color}]:-#3584e4}"
    }

    # =============================================
    # COLOR DEFINITIONS
    # =============================================
    local ACCENT_HEX=$(get_gnome_accent_hex)
    local ACCENT_BG=$(color_to_bg "$ACCENT_HEX")
    local ACCENT_FG=$(color_to_fg "$ACCENT_HEX")
    local PATH_BG=$(color_to_bg "#585858")
    local PATH_FG=$(color_to_fg "#D3D3D3")
    local PATH_BACKGROUND_FG=$(color_to_fg "#585858")
    local GIT_BG=$(color_to_bg "#1d559b")
    local GIT_FG=$(color_to_fg "#ffffff")
    local GIT_BACKGROUND_FG=$(color_to_fg "#1d559b")
    local RESET="\[\e[0m\]"
    local RESET_BG="\[\e[49m\]"
    local RESET_FG="\[\e[39m\]"

    # =============================================
    # GIT BRANCH DETECTION
    # =============================================
    local BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

    # =============================================
    # PROMPT CONSTRUCTION
    # =============================================
    PS1="$ACCENT_BG\[\e[97m\] \u $PATH_BG$ACCENT_FG"
    if [ -n "$BRANCH" ]; then
        PS1+="$PATH_FG \w $GIT_BG$PATH_BACKGROUND_FG"
        PS1+="$GIT_FG  $BRANCH $RESET_BG$GIT_BACKGROUND_FG"
    else
        PS1+="$PATH_FG \w $RESET_BG$PATH_BACKGROUND_FG"
    fi
    PS1+="$RESET "
}


_setup_prompt
unset -f _setup_prompt
