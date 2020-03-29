{ config, lib, pkgs, ...}:


let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.services.nvidia-suspend;
  sleepPkg = pkgs.runCommand "nvidia-sleep" {path=lib.makeBinPath(with pkgs; [coreutils kbd]);}
  ''
    mkdir -p $out/bin
    substituteAll ${./files/nvidia-sleep.sh} $out/bin/nvidia-sleep.sh
    chmod +x $out/bin/nvidia-sleep.sh
    patchShebangs $out/bin/nvidia-sleep.sh
  '';
  sleep = "${sleepPkg}/bin/nvidia-sleep.sh";
in
{
  options = {
    services.nvidia-suspend = {
      enable = mkEnableOption "Enable nvidia suspend service.";
    };
  };

  config = mkIf cfg.enable {

    boot.extraModprobeConfig = ''
      options nvidia NVreg_PreserveVideoMemoryAllocations=1
    '';

    environment.systemPackages = [
      (pkgs.runCommand "system-sleep-nvidia" {inherit sleep;} ''
        mkdir -p $out/lib/systemd/system-sleep
        substituteAll ${./files/nvidia} $out/lib/systemd/system-sleep/nvidia
        chmod +x $out/lib/systemd/system-sleep/nvidia
        patchShebangs $out/lib/systemd/system-sleep/nvidia
        '')
    ];

    systemd.services.nvidia-suspend = {
      description = "NVIDIA system suspend actions";
      before = [ "systemd-suspend.service" ];
      requiredBy = [ "systemd-suspend.service" ];
      script = "${sleep} suspend";
    };

    systemd.services.nvidia-hibernate = {
      description = "NVIDIA system hibernate actions";
      before = [ "systemd-hibernate.service" ];
      requiredBy = [ "systemd-hibernate.service" ];
      script = "${sleep} hibernate";
    };

    systemd.services.nvidia-resume = {
      description = "NVIDIA system resume actions";
      after = [ "systemd-suspend.service" "systemd-hibernate.service" ];
      requiredBy = [ "systemd-suspend.service" "systemd-hibernate.service" ];
      script = "${sleep} resume";
    };

  };
}
