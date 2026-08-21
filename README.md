# mercurial

## Description

Wireguard server switcher.

Nothing to do with the version control system of the same name: this is named for the quality of changing quickly and unpredictably, which is what it does with your VPN endpoint.

Given a directory of WireGuard configurations, `mercurial` brings one up at random, and on each switch moves to a different one:

1. Reads the configurations from `~/.config/wireguard`.
2. Picks one at random, never the one already in use.
3. Brings the tunnel up with `wg-quick`, optionally rewriting the `DNS` line first.
4. Remembers which configuration and interface are current, so the next switch knows what to avoid and what to take down.

## Installation

### 0. Have a recent version of Ruby installed

### 1. Via Homebrew

```shell
$ brew tap thoran/tap
$ brew install thoran/tap/mercurial
```

Then, to install wireguard-tools, which supplies `wg-quick`:

```shell
$ mercurial setup
```

which installs Homebrew if it is not there, and wireguard-tools through it. Both are skipped where already present.

## Dependencies

Two gems, vendored by the formula along with ffi and ostruct, which they bring with them:

1. [switches.rb](https://github.com/thoran/switches.rb), for the command line switches.
2. [sys-proctable](https://github.com/djberg96/sys-proctable), to find `wg-quick` processes left stuck.

The formula also installs `lib` and points `RUBYLIB` at it, that being where `MacOS::IfConfig`, `MacOS::VPN` and the rest come from.

## Usage

### Commands

| Command | What it does |
| --- | --- |
| `setup` | Installs wireguard-tools, and Homebrew first where that is missing too |
| `switch [options]` | Brings the VPN up, or moves it to another endpoint where it is already up |
| `up [options]` | An alias for `switch` |
| `down` | Brings the VPN down, where it is up |
| `status` | Says which configuration is running |

With no command, or with one it does not recognise, it prints its usage and exits 1.

### Options

| Option | Takes | What it does |
| --- | --- | --- |
| `-d`, `--dns`, `--dns_servers` | comma-separated servers | Brings the VPN up with these DNS servers instead of the configuration's own |
| `-c`, `--config` | name, partial name, or path | Chooses the endpoint rather than taking one at random |
| `-r`, `--retain`, `--retain_endpoint` | — | Keeps the current endpoint, for changing DNS alone |
| `-f`, `--format` | `json` | Gives `status` as JSON rather than as plain text |

`--format` is not among the options the script's own `usage()` prints, though it has been there since 0.10.0.

### 1. Bring the VPN up, or move it to another endpoint

```shell
$ mercurial switch
$ mercurial up
```

Where the VPN is already up, both take it down first and come back on a different endpoint — different because the configuration in use is excluded from the draw. Keep more than one configuration in `~/.config/wireguard`: where the only one there is the one already up, the draw comes back empty and `File.join` raises a `TypeError` rather than saying so.

### 2. Choose the endpoint yourself

```shell
$ mercurial switch --config AU.vpn.example.conf
$ mercurial switch -c AU.vpn.example.conf
$ mercurial switch --config AU
```

A full name is looked for in `~/.config/wireguard`. Anything which does not name a file there is matched against the names that are, case insensitively, so `AU` finds the first Australian endpoint.

A path is accepted and checked for existence, but only its filename is carried forward, and that name is then looked for in `~/.config/wireguard` — so `--config /elsewhere/AU.conf` brings up `~/.config/wireguard/AU.conf`, or fails, rather than the file you named.

### 3. Set the DNS servers

```shell
$ mercurial switch --dns_servers 1.1.1.1,1.0.0.1
$ mercurial switch -d 1.1.1.1,1.0.0.1
```

The VPN is dropped and brought back up on a new endpoint, with the `DNS` line rewritten. The rewrite happens in a copy under `/tmp/wireguard`, mode 0600, so the configuration itself is left alone.

### 4. Change DNS without changing endpoint

```shell
$ mercurial switch --dns_servers 1.1.1.1,1.0.0.1 --retain_endpoint
$ mercurial switch -d 1.1.1.1,1.0.0.1 -r
```

Still a drop and a bring-up, but onto the same configuration as before.

### 5. Ask what is running

```shell
$ mercurial status
$ mercurial status --format json
$ mercurial status -f json
```

Plain text is the default, and gives the configuration's path and its `DNS` line. JSON gives the configuration name, its path, the network interface and the DNS servers as a list, for something else to read. Where nothing is up, plain text says `Not operating.` and JSON gives `{"config":null}`.

### 6. Bring it down

```shell
$ mercurial down
```

Where nothing is up, this does nothing at all.

## Notes

1. macOS only. The tunnel is brought up and down with `wg-quick`, and the interfaces are read and destroyed with `ifconfig`.
2. `sudo` is wanted throughout, so for unattended running give it `NOPASSWD` entries. Either add them to `/etc/sudoers`, with `visudo`, or put them in a file of their own at `/etc/sudoers.d/mercurial`.

```
thoran    ALL = NOPASSWD: /opt/homebrew/bin/wg-quick *
thoran    ALL = NOPASSWD: /bin/kill
thoran    ALL = NOPASSWD: /bin/rm -f /var/run/wireguard/*
thoran    ALL = NOPASSWD: /usr/bin/pkill
thoran    ALL = NOPASSWD: /sbin/ifconfig
```

3. All five are wanted, because a run reaches `sudo` six ways: `wg-quick up` and `wg-quick down` for the tunnel, `rm -f` over `/var/run/wireguard` and `pkill` for `wireguard-go` in the cleanup, `kill -9` for a `wg-quick` left stuck, and `ifconfig <interface> destroy` where an interface survives `wg-quick down`. The cleanup runs ahead of every switch, so entries for `wg-quick` alone leave it stopping for a password partway through.
4. The `wg-quick` path above is Homebrew's on Apple silicon. On Intel it is `/usr/local/bin/wg-quick`, and the script takes whatever `FileUtils.which` finds, so make the entry match `command -v wg-quick`.
5. Check the result with `sudo -l` rather than assuming: the `rm` glob is expanded by the shell before `sudo` sees it, so what that entry matches depends on what is in `/var/run/wireguard` at the time.
6. Which configuration is current is kept in `/tmp/mercurial-*.tmp`, and a lock at `/tmp/mercurial.lock` stops two switches running at once. A lock older than five minutes whose process is gone is treated as stale and removed.
7. A switch first clears away any `wg-quick` process left stuck, any interface left in `/var/run/wireguard`, and any lingering `wireguard-go`. This is deliberate: a half-torn-down tunnel otherwise stops the next one coming up.
8. `mercurial` with no command prints the usage and stops, rather than switching.

## Contributing

1. Fork it: `https://github.com/thoran/mercurial/fork`
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Create a new pull request
