{ config, pkgs, lib, userState, ... }:

let
  cfg = (userState.core or {}).monitoring or {};
  enabled = cfg.enabled or false;
  intervalMinutes = toString (cfg.check_interval_minutes or 5);
  reportCfg = cfg.healthcheck_reports or {};
  reportFrequency = reportCfg.frequency or "none";
  reportTime = reportCfg.time or "09:00";
  reportDayOfWeek = reportCfg.day_of_week or "Mon";
  reportDayOfMonth = toString (reportCfg.day_of_month or 1);
  timeParts = lib.splitString ":" reportTime;
  reportHour = if builtins.length timeParts > 0 then builtins.elemAt timeParts 0 else "09";
  reportMinute = if builtins.length timeParts > 1 then builtins.elemAt timeParts 1 else "00";
  reportOnCalendar =
    if reportFrequency == "daily" then "*-*-* ${reportHour}:${reportMinute}:00"
    else if reportFrequency == "weekly" then "${reportDayOfWeek} *-*-* ${reportHour}:${reportMinute}:00"
    else if reportFrequency == "monthly" then "*-*-${reportDayOfMonth} ${reportHour}:${reportMinute}:00"
    else "";

  monitorRunner = pkgs.writeShellScriptBin "caf-vps-monitor-runner" ''
    if command -v caf-vps-monitor-check >/dev/null 2>&1; then
      exec caf-vps-monitor-check --quiet
    fi

    if [ -x "$HOME/.config/cafaye/cli/scripts/caf-vps-monitor-check" ]; then
      exec "$HOME/.config/cafaye/cli/scripts/caf-vps-monitor-check" --quiet
    fi

    exit 0
  '';

  reportRunner = pkgs.writeShellScriptBin "caf-vps-health-report-runner" ''
    if command -v caf-vps-monitor-check >/dev/null 2>&1; then
      exec caf-vps-monitor-check --health-report --quiet
    fi

    if [ -x "$HOME/.config/cafaye/cli/scripts/caf-vps-monitor-check" ]; then
      exec "$HOME/.config/cafaye/cli/scripts/caf-vps-monitor-check" --health-report --quiet
    fi

    exit 0
  '';
in
{
  config = lib.mkIf enabled {
    home.packages = [ monitorRunner reportRunner ];

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

    systemd.user.services.caf-vps-health-report = lib.mkIf (reportFrequency != "none") {
      Unit = {
        Description = "Cafaye VPS Scheduled Health Report";
      };
      Service = {
        ExecStart = "${reportRunner}/bin/caf-vps-health-report-runner";
        Type = "oneshot";
      };
    };

    systemd.user.timers.caf-vps-health-report = lib.mkIf (reportFrequency != "none") {
      Unit = {
        Description = "Cafaye VPS Scheduled Health Report Timer";
      };
      Timer = {
        OnCalendar = reportOnCalendar;
        Unit = "caf-vps-health-report.service";
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
