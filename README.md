# Claude Desktop offline test package for CentOS 8 x86_64

Tested on one CentOS 8 compatible test machine. Requires Flatpak already installed, a working graphical desktop, and x86_64. This does not include Flatpak RPM dependencies. The configured localhost gateway is a placeholder; no model connection is included. Test compatibility on the target machine.

Download all part files, then on Linux reconstruct and verify:

```sh
cat claude-desktop.tar.gpg.part* > claude-desktop.tar.gpg
sha256sum claude-desktop.tar.gpg
```

Expected SHA-256: `920de4b339482749e7fe9f5958d55e425f4991fc75d68479f41aae3c5db3ca9e`

Decrypt and unpack (GnuPG must be available; enter the separately shared passphrase):

```sh
gpg --output claude-desktop.tar --decrypt claude-desktop.tar.gpg
tar -xf claude-desktop.tar
bash install-and-open.sh
```

To reopen after installation:

```sh
flatpak run --env=ZYPAK_ZYGOTE_STRATEGY_SPAWN=0 com.anthropic.ClaudeDesktop --disable-gpu
```

The app uses a placeholder endpoint and cannot respond until an appropriate internal gateway is configured. Credentials and keyring setup are not included.
