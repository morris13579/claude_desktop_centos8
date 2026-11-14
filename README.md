# Claude Desktop CentOS 8 離線安裝與打包

這個專案記錄如何把 Claude Desktop 封裝為 x86_64 Flatpak，供無法直接連外的 CentOS 8 相容桌面環境使用。應用程式使用 Flatpak 內的 Freedesktop 26.08 執行環境，避免直接依賴 CentOS 8 的舊版 glibc。這是**非官方 Flatpak 封裝**，不包含系統 Flatpak RPM、模型服務或正式 API 金鑰。

目前封裝使用 Claude Desktop Debian 版 **5.11492.5**、Freedesktop Platform **26.08**、Electron2 BaseApp **26.08**。一台測試機與一台離線 CentOS 8 相容機器已開啟介面；後者補上 Desktop 指定的 Claude Code **2.1.325** 元件後，已透過內網 Gateway 完成一筆 Desktop 對話。不同系統、桌面、Gateway 和模型仍須各自驗證。

> 套件以 GPG 對稱加密並分割在此儲存庫。密碼需另外取得，請勿放入儲存庫。此儲存庫公開，加密密碼若太簡單不適合保護敏感資料。因為 GitHub 對單檔大小有限制，請下載所有分割檔；不需要 `git clone`。

## 1. 先決條件

- 目標機為 `x86_64`、有可用圖形桌面及一般使用者帳號。
- 系統已安裝可用的 `flatpak`、`gpg`、`sha256sum`、`tar` 和 `zstd`。可用 `uname -m`、`flatpak --version`、`gpg --version`、`zstd --version` 檢查。
- 如果缺少 Flatpak 或其他工具，須另在可上網機器準備適合目標發行版的 RPM 和依賴，透過組織允許的離線方式安裝；本專案未提供這些 RPM。
- Gateway 必須可由 Flatpak 存取，且支援 Desktop 所需的 Anthropic Messages API。真正的 API 金鑰、服務路由和模型由使用者自行提供。
- 官方上游程式及重新散布應遵守適用的授權條款。

## 2. 下載並傳入檔案

在可上網的中間電腦，下載並依組織允許的方式傳入 Linux：

- Desktop 封裝：`claude-desktop.tar.gpg.part00` 至 `claude-desktop.tar.gpg.part07`，共 8 個分割檔。
- 對話元件：`claude-code-2.1.325.zst.gpg.part00` 至 `claude-code-2.1.325.zst.gpg.part02`，共 3 個分割檔。

直接下載網址的格式如下，分別替換最後兩位數字：

- `https://raw.githubusercontent.com/morris13579/claude_desktop_centos8/main/claude-desktop.tar.gpg.part00`
- `https://raw.githubusercontent.com/morris13579/claude_desktop_centos8/main/claude-code-2.1.325.zst.gpg.part00`

在目標機切換到存放分割檔的目錄。所有命令均以一般使用者執行，除安裝系統套件另有需要外不需要 sudo。

## 3. 還原並安裝 Desktop

```bash
cat claude-desktop.tar.gpg.part* > claude-desktop.tar.gpg
sha256sum claude-desktop.tar.gpg
```

合併後 SHA-256 必須為：

```text
920de4b339482749e7fe9f5958d55e425f4991fc75d68479f41aae3c5db3ca9e
```

確認後解密、解壓縮，再執行安裝腳本：

```bash
gpg --output claude-desktop.tar --decrypt claude-desktop.tar.gpg
tar -xf claude-desktop.tar
bash install-and-open.sh
```

GPG 會互動要求密碼。腳本使用 `flatpak install --user --noninteractive --no-deps` 安裝本封裝附帶的 runtime 和應用，並呼叫 `open3p.sh` 建立第三方模式設定。若使用者已有 `Claude-3p/configLibrary` 或 `claude_desktop_config.json`，腳本會停止以免覆寫，請先檢查和備份現有設定。

初始設定的 `http://127.0.0.1:18777`、`local-test-only` 和模型名稱只是**佔位測試值**。看到無法連線是預期的，並不代表模型已設定。一般模式會嘗試載入外部服務，在完全離線環境可能出現白畫面；測試使用的是第三方模式。

日後重新啟動：

```bash
flatpak run --env=ZYPAK_ZYGOTE_STRATEGY_SPAWN=0 com.anthropic.ClaudeDesktop --disable-gpu
```

若看到登入鑰匙圈解鎖提示，需使用該使用者既有的鑰匙圈密碼；取消後介面仍可能開啟，但安全儲存憑證等功能可能不可用。不要刪除既有鑰匙圈來略過此提示。

## 4. 離線補齊 Desktop 對話元件

上述 Desktop 版本在建立本機對話工作階段時會尋找 Claude Code 2.1.325。目標機無法對外時，日誌可能反覆嘗試從 `downloads.claude.ai` 下載 `linux-x64/claude.zst`，介面停在 **Preparing session**。以下做法是針對本封裝和此版本，並已在測試機完成對話；更新 Desktop 版本後，所需版本、校驗值與目錄可能改變。

先在分割檔所在目錄合併與校驗：

```bash
cat claude-code-2.1.325.zst.gpg.part* > claude-code-2.1.325.zst.gpg
sha256sum claude-code-2.1.325.zst.gpg
```

加密檔 SHA-256：

```text
79b4922d1da64233cf38d309442e87da9de8a38d00de4d92f0bb51b4d1bccb85
```

```bash
gpg --output claude-2.1.325.zst --decrypt claude-code-2.1.325.zst.gpg
zstd -d claude-2.1.325.zst -o claude-2.1.325
sha256sum claude-2.1.325.zst claude-2.1.325
```

確認壓縮檔與解壓檔的 SHA-256 分別為：

```text
00b1b977bcc3f32eb69129f0ac3277aafb1aecbfb87c17c0af53806832ed436a  claude-2.1.325.zst
0dc4f4a9a165fc60746d7ae8489712e5fc352f1e7ad4eb22e7141bd0812eb0cf  claude-2.1.325
```

第二個值也可對照 [Anthropic 2.1.325 官方 manifest](https://downloads.claude.ai/claude-code-releases/2.1.325/manifest.json)。檔案來源為官方 `https://downloads.claude.ai/claude-code-releases/2.1.325/linux-x64/claude.zst`。

先退出 Desktop，確認以下目標檔案不存在，避免覆寫其他安裝；此目錄與標記格式是此 Desktop 版本實際觀察到的實作細節：

```bash
flatpak kill com.anthropic.ClaudeDesktop
engine_dir="$HOME/.var/app/com.anthropic.ClaudeDesktop/config/Claude-3p/claude-code/2.1.325/00b1b977bcc3"
mkdir -p "$engine_dir"
if [ -e "$engine_dir/claude" ] || [ -e "$engine_dir/.verified" ]; then
  echo '已有元件，請先檢查，不覆寫'
else
  install -m 755 claude-2.1.325 "$engine_dir/claude" &&
    printf '%s' '00b1b977bcc3f32eb69129f0ac3277aafb1aecbfb87c17c0af53806832ed436a' > "$engine_dir/.verified" &&
    chmod 600 "$engine_dir/.verified"
fi
```

再使用第 3 節指令重新開啟 Desktop，建立新的對話。`.verified` 放的是官方壓縮檔的 SHA-256；安裝之前也必須確認解壓後執行檔的 SHA-256，以免錯誤標記檔案。這個方式不會修改既有的系統 Claude Code 安裝。

## 5. 連接內網 Gateway

第三方模式的使用者設定位於：

```text
~/.var/app/com.anthropic.ClaudeDesktop/config/Claude-3p/configLibrary/
```

`_meta.json` 的 `appliedId` 指向同目錄中對應的設定檔；修改前請關閉 Desktop 並備份。設定檔中可包含敏感 API 金鑰，應限制權限為 `600`、目錄為 `700`，不要將實際金鑰加入 Git、命令列歷史或分享的日誌。配置欄位與範例以 [Claude Desktop 官方第三方配置說明](https://claude.com/docs/third-party/claude-desktop/configuration-format) 為準。

此次測試中，Claude Code 的 `ANTHROPIC_BASE_URL` 和 Desktop Gateway 指向同一個本機位址 `http://127.0.0.1:16079`，使用者環境由本機 tunnel 連接內網服務；這不是其他環境的通用值。未帶認證的 `curl` 收到 401 僅表示服務要求認證，不能證明金鑰錯誤。

Desktop 對模型路由名稱有驗證，不符合其規則的名稱可能會被移除。測試環境的 Gateway 提供 `claude-local-llm`，Desktop 已接受此路由且實際對話有回覆。**不同路由名稱不一定指向同一個底層模型**，請由 Gateway 管理者確認對應關係。手動設定模型清單及停用模型自動探索的概念範例：

```json
{
  "inferenceProvider": "gateway",
  "inferenceGatewayBaseUrl": "http://127.0.0.1:16079",
  "inferenceGatewayApiKey": "請在本機安全填入，不要提交",
  "inferenceGatewayAuthScheme": "x-api-key",
  "inferenceModels": [{"name": "claude-local-llm"}],
  "modelDiscoveryEnabled": false,
  "chatTabEnabled": true
}
```

模型 ID 和認證方式必須依實際 Gateway 修改；在既有檔案中修改時應保留其他必要欄位。修改設定後重啟 Desktop。Desktop 的設定頁曾出現 `Couldn’t load configuration`；目前尚未確認其直接原因。離線日誌中也可能出現向 Anthropic 外部服務請求逾時，這些紀錄本身不能證明內網推論已失敗。

## 6. 在可上網機器重新製作 Flatpak

現有封裝是將 **官方預先編譯的 Debian 應用樹重新封裝**，不是從 Claude Desktop 原始碼編譯。Electron2 BaseApp 已提供 zypak；應用使用 zypak wrapper 搭配 Flatpak sandbox。不要把 Desktop 預設以 root 執行，也不要為了排障隨意關閉 sandbox。

準備：

1. 可上網、`x86_64` 的 Linux 建置環境，安裝 `flatpak`、`ostree`、`ar`、`tar`、`sed` 及標準 coreutils。
2. 在該環境安裝 Freedesktop Platform 和 SDK 26.08、Electron2 BaseApp 26.08，確保 OSTree repo 內有相應 refs；套件可能隨上游更新，固定版本與 commit 才能重現舊結果。
3. 取得官方 Debian `claude-desktop_5.11492.5_amd64.deb`，SHA-256 為 `b96208b207e450b740f7dbe304f6077fed80e7f3d37ddd545991c4e8201564cf`。官方 apt 下載來源：`https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/`。
4. 將本儲存庫的 `build/rebuild.sh`、`build/reference.tar` 和 Debian 檔放進**新的空建置目錄**。`reference.tar` 是 wrapper、desktop 檔、metainfo 和圖示，不包含 Debian 應用或執行環境。

建置腳本按實際封裝流程重建：從 OSTree checkout Electron2 BaseApp，解開 Debian 的 `data.tar.xz`，將應用樹和 wrapper 放入 `/app`，用 `flatpak build-finish`、`build-export`、`build-bundle` 產生應用及 runtime bundle。例如 user installation 的 OSTree repo 路徑：

```bash
export OSTREE_REPO="$HOME/.local/share/flatpak/repo"
# 如果 repo 中 BaseApp 使用 app ref，可自行改為 app/org.electronjs.Electron2.BaseApp/x86_64/26.08
export BASE_REF="runtime/org.electronjs.Electron2.BaseApp/x86_64/26.08"
bash rebuild.sh
```

原測試採用的上游 commit：Platform `df26daaf9d07610b4a72cc4585566194051275ac68396597b06474396f66427c`、SDK `a1b744b072d9f55d061e35382547ae80dad8d92abecc1da7dc1818de2daabfd3`、BaseApp `b91eabd5bd9a7ac4f7684aeba9126ec381d8c87be64cb834b775ffc35915a541`。上游可能不再保留這些 commit；請自行確認取得方式與可信來源。原測試以 OSTree static delta 將材料搬到離線建置機，BaseApp 另建立了 `app/...` ref 供 checkout。

**重建限制：** `build/rebuild.sh` 是根據當時手動步驟整理的配方，尚未在乾淨建置環境重新跑過；上游 ref、runtime 或打包工具不同都可能需要調整，產物也不保證位元組完全相同。原測試 bundle SHA-256：

```text
332ab9da1928fc14861bf0355d12f5c27de5d657c7fbca9f7ee339295441f31a  claude-desktop-offline.flatpak
6accbf58ac369f769003c62120a5c907b72881cbdb5dc9b86014cb77233ca84c  freedesktop-platform-26.08.flatpak
```

完整離線部署還需要將新 bundle、第三方模式的安全設定方式，以及 Desktop 指定版本的對話元件一起準備；請先在與目標相近的測試機驗證，不要把本機 API 金鑰打進封裝。
