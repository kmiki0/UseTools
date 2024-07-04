# SQL Serverのデータベースが複数ある構成で、リストアを(半)自動化した話

## はじめに
月次バッチの開発やテストをしているときに、データベースのリストアをしながら開発をしていたのですが、  
GUI操作で、リストアしていくと運用しているデータベースが複数あればあるほど、手間がかかっていました。
その時に、これらを半自動化まで出来るようにしたので、備忘録的に残しておきます。
今回のバックアップファイルは、完全バックアップを想定しています。

### 環境
- SQL Server 2019
- Windows 10

### 処理イメージ

1. リストアするデータベースのリストをTXTファイルから読み取る
2. テキストを元にSQLを生成して、ファイルに出力する
3. SQLファイルをSQL Serverに接続して実行する

> 結構やってることはシンプルで、リストア用のSQLを生成して一括で実行するだけです。

## Management Studioでリストアする方法
- ![データベース復元前のウィンドウ](https://)
- このスクリプトを実行すると、データベースの復元に使用されるSQLが生成される。

> 自分が使用していたリストア時のオプション
> - ソース     ：☑デバイス ⇒ ローカルのバックアップファイル（完全バックアップ）
> - サーバー接続：☑接続先データベースへの既存の接続を閉じる

```sql
ALTER DATABASE [DBNAME] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE [DBNAME] FROM  DISK = N'D:\BKFolder\DBNAME_bk.bak' WITH  FILE = 1,  NOUNLOAD,  STATS = 5;
ALTER DATABASE [DBNAME] SET MULTI_USER;
```
- このSQLを実行すると、データベースがリストアされる。

### ALTER DATABASEのオプション
- SET SINGLE_USER 
    - ユーザー接続を1つに制限する。
    - 他のユーザーがデータベースに接続していると、データベースに対する接続は警告なく切断される。
- WITH ROLLBACK IMMEDIATE
    - トランザクションをロールバックして、他のユーザーの接続を切断する。
- SET MULTI_USER
  - データベースに接続するための権限を持つ、すべてのユーザーが許可する。

### RESTORE DATABASEのオプション
- FROM DISK  
    - バックアップファイルのパスを指定する。
- WITH FILE = 1
  - バックアップファイルセットの最初のリストを指定する。
  - バックアップファイルが複数ある場合に使用する。
- NOUNLOAD
  - RESTORE 操作の後、テープ ドライブにテープを読み込んだままにすることを指定する。
- STATS = 5
  - バックアップ操作の進行状況を示すメッセージを表示する。
  - 今回の場合、5% ごとにメッセージを表示するということだが、あまり正確ではないらしい。。。

## SQL自動生成用
なにわともあれ、ソースということで

```ps1
  #各変数の値は環境に合わせて適宜設定
  $backup_list = "backupfiles.txt"
  $bakpath = "D:\BackupData"
  $outfile = "output.sql"

  # バックアップリストを読み込む
  $bakfiles = Get-Content $backup_list

  foreach ($bakfile in $bakfiles) {
    # BAKファイル名からDB名を取得
    $backup_file = Split-Path $bakfile -Leaf
    $dbname = $backup_file.split("_")[0]

      # バックアップを復元するスクリプトを出力
      $sb = New-Object System.Text.StringBuilder
      
    [void]$sb.AppendLine("ALTER DATABASE ${dbname} SET SINGLE_USER WITH ROLLBACK IMMEDIATE;")
    [void]$sb.AppendLine("RESTORE DATABASE ${dbname} FROM DISK='${bakpath}\${backup_file}' WITH RECOVERY")
    [void]$sb.AppendLine("ALTER DATABASE ${dbname} SET MULTI_USER;")

      # 結果をファイルに追記出力
      Write-Output $sb.ToString() | Out-File -Append $outfile
  }

  # SQL Serverに接続してリストアを実行
  $serverName = "サーバー名 or アドレス"
  $userName = "サーバーのユーザー名"
  $userPassword = "サーバーのパスワード"
  sqlcmd -S $serverName -U $userName -P $userPassword -i $outfile
```

### ちょろっと解説
そんなに処理自体は複雑ではないので解説ということでもないですが、
前提として、バックアップファイルのリストをテキストファイルに記載しておく必要があります。
このソースでは、以下のようなファイルを想定しています。

- backupfiles.txt
```txt
dbName1_20110123.bak
dbName2_20110123.bak
dbName3_20110123.bak
…
```
- 書きながら思ったのですがBAKファイルを読み込むところで、  
  色々工夫すれば特定のデータベースのみリストア出来たりすると思います。


::: note warm
実行する際に、実行ポリシーに引っかかることがあるかもしれませんが  
その場合は以下のようにして実行してください。

```cmd
PowerShell -ExecutionPolicy RemoteSigned .\restore.ps1
```

こうすることで、実行ポリシーを一時的に変更して実行することが出来ます。
:::

## おわりに
今回は、SQL Serverのリストアの自動化について書いてみましたが、同じような要領でバックアップの取得も出来ると思います。
それこそ、バックアップ時に　`backupfils.txt`にバックアップファイル名を追記していけば、
バックアップ⇒リストアという流れを自動化することが出来ると思いますので、お好きにしてみてください。
