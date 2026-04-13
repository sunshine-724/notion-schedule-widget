# NotionSchedule Widget

Notionの特定のページに書かれた「今日のスケジュール」を読み取り、iPhone / iPad / Mac のウィジェットとして「いまの予定」「次の予定」を表示する専用アプリです。

## 1. 事前準備：Notion APIトークンの取得
アプリにNotionのデータを読み取らせるために、専用のキー（トークン）を発行します。

1. [Notion Integrations](https://www.notion.so/my-integrations) にアクセスします。
2. 「新しいインテグレーション（New integration）」を作成します。
3. 発行された **「内部インテグレーションシークレット」**（`ntn_`等から始まる文字列）をコピーします。
4. ご自身のNotionワークスペースに戻り、予定を書き込む予定のページ（またはその親階層のページ）を開きます。
5. ページ右上の「･･･（メニュー）」を開き、**「コネクトの追加」** から先ほど作成したインテグレーションを追加します。（これを忘れるとAPIからページが見えません）

## 2. 実機で使用するための設定（Xcode）
コード内のバンドルIDが汎用的な `com.example` になっているため、実機へインストールする際はご自身専用のIDに変更する必要があります。

### A. ID（ドメイン）の変更
ソースコード内の `example` の部分を、他人と被らないご自身のID（例: `com.myname` など）に置き換えます。変更が必要な箇所は以下の4つです。

- `project.yml` の `bundleIdPrefix: com.example`
- `App/NotionSchedule.entitlements` の `group.com.example.NotionScheduleWidget`
- `Widget/NotionScheduleWidget.entitlements` の同箇所
- `Shared/SharedStorage.swift` 3行目付近の `suitName` の同箇所

### B. プロジェクトファイルの再生成とTeamの割り当て
1. ターミナルでこのディレクトリを開き、ツールを使って設定を反映します。
   ```bash
   /opt/homebrew/bin/xcodegen generate
   ```
2. 生成された `NotionSchedule.xcodeproj` をダブルクリックして Xcode で開きます。
3. Xcode の左側（プロジェクトナビゲーター）の最上部にある青いアイコン `NotionSchedule` をクリックします。
4. `TARGETS` の `NotionSchedule` と `NotionScheduleWidget` の両方について、**「Signing & Capabilities」** タブを開き、`Team` のドロップダウンからご自身の Apple ID を選択します。
5. 画面上部の再生ボタン（▶︎）を押して、アプリを実機へ転送します。

## 3. アプリの使い方

1. インストールされたアプリを起動します。
2. 取得した「インテグレーションシークレット」を入力し **[Save Token]** を押します。
3. Notionに **`YYYY-MM-DD 今日のスケジュール`** というタイトルのページを作成します（例: `2026-04-09 今日のスケジュール`）。
4. ページ内に以下のように書いてください。
   ```markdown
   ### Today's Plan
   - 10:00-11:00 タスクA
   - 11:30-12:00 タスクB
   ---
   ```
   ※ `### Today's Plan` ヘッダーから `---` （区切り線）の間に、時刻ベース（`HH:mm-HH:mm`）で記載したものが認識されます。
5. アプリの **[Fetch Today's Plan & Update Widget]** ボタンを押します。
6. ホーム画面に戻り、ウィジェットを追加すると、現在の進行中予定や次の予定が表示されます！ウィジェットをタップすると直接該当のNotionページへと遷移します。

## 4. 自動更新の仕様と仕組みについて
**現状では「毎日Notionから最新データをダウンロードする処理」は手動で行う仕様になっています。**

1. **Notionから本体へのデータダウンロード（一日１回・手動）**
   - 毎日、朝などにアプリを開き「Fetch Today's Plan」ボタンを押してください。最新の予定が本体内にダウンロード（キャッシュ）されます。
2. **ウィジェットの表示切り替え（アプリを閉じていても完全自動）**
   - データさえダウンロードしておけば、その日１日の「今の予定」や「次の予定」への表示切り替えは、予定の境界時間に合わせて**OS側で完全自動で更新**されます（毎回アプリを開き直す必要はありません）。
