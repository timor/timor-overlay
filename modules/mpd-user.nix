{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.mpdUser;
  clfswm = cfg.package;
  # inherit (pkgs.luaPackages) getLuaPath getLuaCPath;
  playlist_dir = "${cfg.dataDir}/playlists";
  mpdConf = pkgs.writeText "mpd.conf" (''
    music_directory     "${cfg.musicDirectory}"
    playlist_directory  "${playlist_dir}"
    db_file             "${cfg.dataDir}/tag_cache"
    state_file          "${cfg.dataDir}/state"
    sticker_file        "${cfg.dataDir}/sticker.sql"

    ${optionalString (cfg.network.listenAddress != "any") ''bind_to_address "${cfg.network.listenAddress}"''}
    ${optionalString (cfg.network.port != 6600)  ''port "${toString cfg.network.port}"''}

    ${cfg.extraConfig}
  '' + optionalString(config.hardware.pulseaudio.enable) ''
    audio_output {
      type "pulse"
      name "Pulse output"
    }
  '');

in

{

  ###### interface

   options = {

    services.mpdUser = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable MPD, the music player daemon.
        '';
      };

      musicDirectory = mkOption {
        type = types.str;
        default = "${cfg.dataDir}/music";
        description = ''
          The directory where mpd reads music from.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra directives added to to the end of MPD's configuration file,
          mpd.conf. Basic configuration like file location and uid/gid
          is added automatically to the beginning of the file. For available
          options see <literal>man 5 mpd.conf</literal>'.
        '';
      };

      dataDir = mkOption {
        type = types.str;
        default = "~/.config/mpd";
        description = ''
          The directory where MPD stores its state, tag cache,
          playlists etc.
        '';
      };

      # user = mkOption {
      #   type = types.str;
      #   default = name;
      #   description = "User account under which MPD runs.";
      # };

      # group = mkOption {
      #   type = types.str;
      #   default = name;
      #   description = "Group account under which MPD runs.";
      # };

      network = {

        listenAddress = mkOption {
          type = types.str;
          default = "127.0.0.1";
          example = "any";
          description = ''
            The address for the daemon to listen on.
            Use <literal>any</literal> to listen on all addresses.
          '';
        };

        port = mkOption {
          type = types.int;
          default = 6600;
          description = ''
            This setting is the TCP port that is desired for the daemon to get assigned
            to.
          '';
        };

      };

      # dbFile = mkOption {
      #   type = types.str;
      #   default = "${cfg.dataDir}/tag_cache";
      #   description = ''
      #     The path to MPD's database.
      #   '';
      # };
    };

  };


  ###### implementation

  config = mkIf cfg.enable {

    systemd.user.services.mpd = {
      
      after = [ "network.target" "sound.target" ];
      description = "Music Player Daemon (User)";
      wantedBy = [ "default.target" ];
      preStart = ''
        mkdir -p ${cfg.dataDir};
	mkdir -p ${playlist_dir};
	mkdir -p ${cfg.musicDirectory};
      '';
      script = "${pkgs.mpd}/bin/mpd --no-daemon --stderr ${mpdConf}";
    };

  };
}
