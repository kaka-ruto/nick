{ config, pkgs, lib, userState, ... }:

let
  cfg = (userState.core or {}).monitoring or {};
  enabled = cfg.enabled or false;
  intervalMinutes = toString (cfg.check_interval_minutes or 5);

  monitorRunner = pkgs.writeShellScriptBin "caf-vps-monitor-runner" ''
    if command -v caf-vps-monitor-check >/dev/null 2>&1; then
      exec caf-vps-monitor-check --quiet
    fi

    if [ -x "$HOME/.config/cafaye/cli/scripts/caf-vps-monitor-check" ]; then
      exec "$HOME/.config/cafaye/cli/scripts/caf-vps-monitor-check" --quiet
    fi

    exit 0
  '';
in
{
  config = lib.mkIf enabled {
    home.packages = [ monitorRunner ];

    systemd.user.services.caf-vps-monitor = {
      Unit = {
        Description = "Cafaye VPS Monitoring Check";
      };
      Service = {
        ExecStart = "${monitorRunner}/bin/caf-vps-monitor-runner";
        Type = "oneshot";
      };
    };

    systemd.user.timers.caf-vps-monitor = {
      Unit = {
        Description = "Cafaye VPS Monitoring Timer";
      };
      Timer = {
        OnCalendar = "*:0/${intervalMinutes}";
        Unit = "caf-vps-monitor.service";
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
