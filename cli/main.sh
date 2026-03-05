#!/bin/bash

# Main Cafaye OS CLI
# Usage: caf

export CLI_DIR="$(dirname "$(realpath "$0")")"
export PATH="$CLI_DIR/scripts:$PATH"

# Ensure Trace ID exists for cross-node correlation
if [[ -z "${CAFAYE_TRACE_ID:-}" ]]; then
    export CAFAYE_TRACE_ID="caf-$(date +%s)-$RANDOM"
fi

caf_choose_menu() {
    local header="$1"
    shift
    local -a options=("$@")

    if command -v fzf >/dev/null 2>&1; then
        printf '%s\n' "${options[@]}" | \
            fzf --height=14 --reverse --prompt "${header}> " \
                --header "j/k or arrows: move • enter/l: select • h: back • /: search" \
                --bind "j:down,k:up,up:up,down:down,l:accept,h:abort,/:change-prompt(${header} search> )"
        return $?
    fi

    gum choose --cursor "👉 " --header "$header" "${options[@]}"
}

show_main_menu() {
    clear
    caf-logo-show
    echo ""

    choice=$(caf_choose_menu "Main Menu" \
        "📦 Install (Languages & Frameworks)" \
        "⚙️  Services (Postgres, Redis)" \
        "🎨 Style (Themes & UI)" \
        "🏗️  Fleet (Manage Nodes)" \
        "🏥 Status (System Health)" \
        "🔐 Secrets" \
        "🔄 Update & Rebuild" \
        "  About" \
        "👋 Exit")

    case "$choice" in
        *"Install"*) show_install_menu ;;
        *"Services"*) show_services_menu ;;
        *"Style"*) show_style_menu ;;
        *"Fleet"*) show_fleet_menu ;;
        *"Status"*) show_status_menu ;;
        *"Secrets"*) caf-secrets ;;
        *"Update"*) run_system_update ;;
        *"About"*) show_about ;;
        *"Exit"*) exit 0 ;;
        *) show_main_menu ;;
    esac
}

show_fleet_menu() {
    choice=$(caf_choose_menu "Fleet Management" \
        "📋 Dashboard (Status)" \
        "🏗️  Manage VPS (Forge CRUD)" \
        "📤 Sync Files to Fleet" \
        "🛠️  Apply Fleet Changes" \
        "🔗 Attach All (TMUX)" \
        "⬅️  Back")

    case "$choice" in
        *"Dashboard"*) caf-fleet status; read -p "Press enter..." ;;
        *"Manage"*) caf-vps ;;
        *"Sync"*) caf-fleet sync ;;
        *"Apply"*) caf-fleet apply ;;
        *"Attach"*) caf-fleet attach ;;
        "⬅️  Back") show_main_menu ;;
        *) show_fleet_menu ;;
    esac
    show_fleet_menu
}

show_status_plain() {
    caf-status
}

show_install_menu() {
    choice=$(caf_choose_menu "Install Submenu" \
        "🛤️  Ruby on Rails" \
        "🐎 Django" \
        "⚛️  Next.js" \
        "🦀 Rust" \
        "Hamster Go" \
        "🟢 Node.js" \
        "🐍 Python" \
        "💎 Ruby" \
        "🐳 Docker" \
        "🗄️  Docker DBs" \
        "⬅️  Back")

    case "$choice" in
        *"Rails"*) toggle_framework "rails" "Ruby & PostgreSQL" ;;
        *"Django"*) toggle_framework "django" "Python & PostgreSQL" ;;
        *"Next.js"*) toggle_framework "nextjs" "Node.js" ;;
        "🦀 Rust") toggle_language "rust" ;;
        "Hamster Go") toggle_language "go" ;;
        "🟢 Node.js") toggle_language "nodejs" ;;
        "🐍 Python") toggle_language "python" ;;
        "💎 Ruby") toggle_language "ruby" ;;
        "🐳 Docker") toggle_service "docker" ;;
        *"Docker DBs"*) caf-docker-db-install ;;
        "⬅️  Back") show_main_menu ;;
        *) show_main_menu ;;
    esac
}

show_services_menu() {
    choice=$(caf_choose_menu "Backend Services" \
        "🐘 PostgreSQL" \
        "🧠 Redis" \
        "⬅️  Back")

    case "$choice" in
        *"PostgreSQL"*) toggle_backend_service "postgresql" ;;
        *"Redis"*) toggle_backend_service "redis" ;;
        "⬅️  Back") show_main_menu ;;
        *) show_main_menu ;;
    esac
}

toggle_backend_service() {
    service=$1
    current=$(caf-state-read "services.$service")
    
    if [[ "$current" == "true" ]]; then
        gum confirm "Disable $service (System Service)?" && caf-state-write "services.$service" "false"
    else
        gum confirm "Enable $service (System Service)?" && caf-state-write "services.$service" "true"
    fi
    
    if gum confirm "Apply changes now? (Rebuild)"; then
        caf-system-rebuild
    fi
    show_services_menu
}

run_system_update() {
    gum confirm "Perform a full system update and rebuild?" || return
    
    # Run pre-update hook if any
    caf-hook-run pre-update
    
    # Execute rebuild
    caf-system-rebuild
    
    # Run post-update hook
    caf-hook-run post-update
    
    caf-task-done "System Update"
    read -p "Press enter to return..."
    show_main_menu
}

show_status_menu() {
    choice=$(caf_choose_menu "Status Submenu" \
        "🏥 System Health" \
        "📡 VPS Monitoring Setup" \
        "🧪 Send Monitoring Test Alert" \
        "🏭 Factory CI/CD Status" \
        "👁️  Watch Factory (Live)" \
        "🔍 Check Current Commit" \
        "⬅️  Back")

    case "$choice" in
        *"System Health"*) show_system_health ;;
        *"Monitoring Setup"*) caf-vps-monitor-setup ;;
        *"Test Alert"*) caf-vps-monitor-check --notify-test ;;
        *"Factory CI/CD"*) caf-factory-check ;;
        *"Watch Factory"*) caf-factory-check --watch ;;
        *"Current Commit"*) check_current_commit ;;
        "⬅️  Back") show_main_menu ;;
        *) show_main_menu ;;
    esac
    
    read -p "Press enter to return..."
    show_status_menu
}

check_current_commit() {
    local current_commit
    current_commit=$(git rev-parse HEAD 2>/dev/null | cut -c1-7)
    
    if [[ -z "$current_commit" ]]; then
        echo "❌ Not in a git repository"
        return 1
    fi
    
    echo "🔍 Checking CI status for current commit: $current_commit"
    echo ""
    caf-factory-check --commit "$current_commit"
}

show_system_health() {
    clear
    echo "🏥 Cafaye System Health"
    echo "------------------------"
    
    # Check Tailscale
    if caf-cmd-present tailscale; then
        ts_status=$(tailscale status --short 2>/dev/null || echo "Not connected")
        echo "🌐 Tailscale: $ts_status"
    fi
    
    # Check Docker
    if caf-cmd-present docker; then
        if docker info >/dev/null 2>&1; then
            echo "🐳 Docker: Active"
        else
            echo "🐳 Docker: Inactive (or no permission)"
        fi
    fi

    # Check Home Manager generation
    if command -v home-manager &> /dev/null; then
        gen=$(home-manager generations | head -n 1 | awk '{print $5}')
        echo "📌 HM Generation: $gen"
    fi
    
    echo "------------------------"
}

show_style_menu() {
    choice=$(caf_choose_menu "Style Submenu" \
        "🌙 Catppuccin Mocha" \
        "🌃 Tokyo Night" \
        "🌿 Everforest" \
        "⬅️  Back")

    case "$choice" in
        *"Mocha"*) preview_theme_change "catppuccin-mocha" "Catppuccin Mocha" ;;
        *"Tokyo Night"*) preview_theme_change "tokyo-night" "Tokyo Night" ;;
        *"Everforest"*) preview_theme_change "everforest" "Everforest" ;;
        "⬅️  Back") show_main_menu ;;
        *) show_main_menu ;;
    esac
    show_style_menu
}

preview_theme_change() {
    local next_theme="$1"
    local next_label="$2"
    local previous_theme
    previous_theme="$(caf-state-read "interface.theme" 2>/dev/null || echo "catppuccin-mocha")"

    caf-state-write "interface.theme" "$next_theme"
    caf-hook-run theme-set
    echo "Previewing $next_label..."
    echo "Keep this theme?"
    if ! gum confirm; then
        caf-state-write "interface.theme" "$previous_theme"
        caf-hook-run theme-set
        echo "Reverted to ${previous_theme}."
    fi
}

toggle_language() {
    lang=$1
    current=$(caf-state-read "languages.$lang")
    
    if [[ "$current" == "true" ]]; then
        gum confirm "Uninstall $lang?" && caf-state-write "languages.$lang" "false"
    else
        gum confirm "Install $lang?" && caf-state-write "languages.$lang" "true"
    fi
    
    if gum confirm "Apply changes now? (Rebuild)"; then
        caf-system-rebuild
    fi
    show_install_menu
}

toggle_service() {
    service=$1
    current=$(caf-state-read "dev_tools.$service")
    
    if [[ "$current" == "true" ]]; then
        gum confirm "Disable $service?" && caf-state-write "dev_tools.$service" "false"
    else
        gum confirm "Enable $service?" && caf-state-write "dev_tools.$service" "true"
    fi
    
    if gum confirm "Apply changes now? (Rebuild)"; then
        caf-system-rebuild
    fi
    show_install_menu
}

toggle_framework() {
    framework=$1
    deps=$2
    current=$(caf-state-read "frameworks.$framework")
    
    if [[ "$current" == "true" ]]; then
        gum confirm "Uninstall $framework stack?" && caf-state-write "frameworks.$framework" "false"
    else
        echo "💡 Note: Installing $framework will also enable: $deps"
        gum confirm "Install $framework stack?" && caf-state-write "frameworks.$framework" "true"
    fi
    
    if gum confirm "Apply changes now? (Rebuild)"; then
        caf-system-rebuild
    fi
    show_install_menu
}

show_about() {
    if caf-cmd-present fastfetch; then
        fastfetch --config ~/.config/cafaye/fastfetch/config.jsonc
    else
        caf-logo-show
        echo "Cafaye distributed development infrastructure"
    fi
    read -p "Press enter to return..."
    show_main_menu
}

# Handle direct commands
case "$1" in
    install)
        if [[ -n "$2" ]]; then
            # Direct tool installation eg: caf install ruby
            tool="$2"
            distro=""
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --distro) distro="${2:-}"; shift 2 ;;
                    *) shift ;;
                esac
            done
            echo "⏳ Enabling ${tool}..."
            # Map tool to state key (simplified for MVP)
            case "$tool" in
                neovim|nvim)
                    if [[ -z "$distro" ]]; then
                        echo "Usage: caf install neovim --distro <astronvim|lazyvim|nvchad|lunarvim>"
                        exit 1
                    fi
                    caf-editor-distribution-set nvim "$distro"
                    "$HOME/.config/cafaye/cli/scripts/caf-nvim-distribution-setup"
                    ;;
                ruby) caf-state-write "languages.ruby" "true" ;;
                python) caf-state-write "languages.python" "true" ;;
                nodejs) caf-state-write "languages.nodejs" "true" ;;
                go) caf-state-write "languages.go" "true" ;;
                rust) caf-state-write "languages.rust" "true" ;;
                rails) caf-state-write "frameworks.rails" "true" ;;
                django) caf-state-write "frameworks.django" "true" ;;
                nextjs) caf-state-write "frameworks.nextjs" "true" ;;
                postgresql) caf-state-write "services.postgresql" "true" ;;
                redis) caf-state-write "services.redis" "true" ;;
                docker) caf-state-write "dev_tools.docker" "true" ;;
                *) echo "Unknown tool: $tool"; exit 1 ;;
            esac
            echo "✅ $tool enabled in state."
            if gum confirm "Apply changes now?"; then
                if command -v gum >/dev/null 2>&1; then
                    gum spin --spinner dot --title "Applying ${tool} changes..." -- caf-system-rebuild
                else
                    caf-system-rebuild
                fi
            fi
        else
            show_install_menu
        fi
        ;;
    config)
        shift
        caf-config "$@"
        ;;
    status)
        show_status_plain
        ;;
    project)
        shift
        caf-project "$@"
        ;;
    doctor)
        caf-system-doctor
        ;;
    apply)
        caf-system-rebuild
        ;;
    sync)
        caf-sync "$2"
        ;;
    fleet)
        shift
        caf-fleet "$@"
        ;;
    vps)
        shift
        caf-vps "$@"
        ;;
    test)
        shift
        caf-test "$@"
        ;;
    update)
        shift
        caf-update "$@"
        ;;
    system)
        action="$2"
        shift 2
        case "$action" in
            harden)
                caf-system-harden "$@"
                ;;
            doctor)
                caf-system-doctor "$@"
                ;;
            rebuild|apply)
                caf-system-rebuild "$@"
                ;;
            update)
                caf-update "$@"
                ;;
            *)
                echo "Usage: caf system <harden|doctor|rebuild|update>"
                exit 1
                ;;
        esac
        ;;
    backup)
        if [[ "$2" == "status" ]]; then
            caf-backup-status
        else
            echo "Usage: caf backup status"
        fi
        ;;
    ci)
        shift
        caf-ci-status "$@"
        ;;
    --help|-h)
        echo "Cafaye CLI"
        echo ""
        echo "Commands:"
        echo "  install [tool]  Install a tool (ruby, rails, etc.)"
        echo "  config          Open interactive configuration"
        echo "  config ...      Manage autostatus/editor/distro settings"
        echo "  doctor          Check system health"
        echo "  status          Show Cafaye status"
        echo "  project ...     Manage project sessions"
        echo "  apply           Apply state changes (rebuild)"
        echo "  sync [push/pull] Sync state with Git source of truth"
        echo "  fleet [status/add/remove/sync/apply/attach/switch] Manage remote nodes"
        echo "  vps [list/create/delete/status] Manage Cloud VPS instances"
        echo "  test [--nix]    Run syntax or behavioral tests"
        echo "  update          Update Cafaye foundation to latest version"
        echo "  backup status   Show backup repository status"
        echo "  ci ...          Show CI status/logs (e.g. --latest --logs)"
        echo ""
        echo "Run without arguments for interactive menu."
        ;;
    *)
        if [[ -n "$1" ]]; then
            echo "Unknown command: $1"
            exit 1
        fi
        show_main_menu
        ;;
esac
