# 送信側PG 文字化け対応案

## 問題の概要

送信側PGでCSVを出力する際、Oracle（UTF-8）のデータをShift_JIS（CP932）で書き込んでいるが、CP932に存在しない文字が「?」に文字化けし、受信側PGでエラーが発生している。

## 原因

### 文字化けの発生箇所

```
Oracle（UTF-8）
  → VB.NET（内部Unicode）
    → StreamWriter（Encoding.Default = Shift_JIS/CP932）
      → CSV出力 ← ★ CP932にマッピングできない文字が「?」になる
```

### 該当コード

```vb
System.IO.StreamWriter(strFilePath, false, System.Text.Encoding.Default)
```

- .NET Framework + 日本語Windowsでは `Encoding.Default` = Shift_JIS（CP932）
- Unicode → CP932変換時に、CP932に存在しない文字はデフォルトで「?」に置換される

### CP932で変換できない文字の例（住所データで発生しやすいもの）

| 文字 | Unicode | CP932 | 備考 |
|---|---|---|---|
| 髙（はしごだか） | `U+9AD9` | ❌ 不可 | 「高」の旧字体 |
| 﨑（たつさき） | `U+FA11` | ❌ 不可 | 「崎」の異体字 |
| 濵（はま） | `U+6FF5` | ❌ 不可 | 「浜」の旧字体 |
| 麵（めん） | `U+9EB5` | ❌ 不可 | 「麺」(`U+9EBA`) なら可 |
| −（MINUS SIGN） | `U+2212` | ❌ 不可 | 「－」(`U+FF0D`) なら可 |
| ‐（HYPHEN） | `U+2010` | ❌ 不可 | 見た目が「－」と同じ |
| –（EN DASH） | `U+2013` | ❌ 不可 | 見た目が「－」と同じ |
| —（EM DASH） | `U+2014` | ❌ 不可 | 見た目が「－」と同じ |

※ 特にハイフン系は見た目がほぼ同一でもUnicodeコードポイントが異なり、CP932変換可否が分かれる。

---

## 対応案

### 対応案: VB.NET側で変換不可文字を「■」に置換

DB抽出後、CSV書き込み前に変換不可文字を検出して「■」に置換する。

#### 実装方法

`EncoderFallback` を使って、CP932に変換できない文字を自動的に「■」に置換する。

```vb
''' <summary>
''' CP932で変換できない文字を「■」に置換してCSV書き込み用の文字列を返す
''' </summary>
Public Function ReplaceUnmappableChars(value As String) As String
    If String.IsNullOrEmpty(value) Then Return value

    Dim enc As System.Text.Encoding = System.Text.Encoding.GetEncoding(
        932,
        New System.Text.EncoderReplacementFallback("■"),
        System.Text.DecoderFallback.ReplacementFallback
    )

    Dim bytes() As Byte = enc.GetBytes(value)
    Return enc.GetString(bytes)
End Function
```

#### 呼び出し例

```vb
' CSV書き込み前に対象カラムに適用
Dim address3 As String = dr("住所３").ToString()
address3 = ReplaceUnmappableChars(address3)
```

#### メリット・デメリット

| 観点 | 評価 |
|---|---|
| 実装コスト | ◎ 低い（関数1つ追加） |
| 網羅性 | ◎ CP932に無い文字を自動的にすべて拾える |
| 保守性 | ◎ 個別の文字リスト管理が不要 |
| データ品質 | △ 元の文字情報が失われる |

---

## EncoderReplacementFallback 詳細解説

### 概要

.NET の文字コード変換において、**マッピングできない文字が出てきたときの処理方法**を制御する仕組み。
`Encoding.GetEncoding` の第2引数で指定する。

### デフォルトの挙動（現行の問題）

`Encoding.GetEncoding(932)` のデフォルトFallbackは `EncoderReplacementFallback("?")` である。

```
Unicode「髙」→ CP932に無い → Fallback発動 →「?」に置換
```

これが現在発生している「?」文字化けの正体。

### Fallback の種類

| 種類 | クラス名 | 挙動 | 用途 |
|---|---|---|---|
| 置換Fallback | `EncoderReplacementFallback` | 指定した文字列に置き換える | 今回の対応で使用 |
| 例外Fallback | `EncoderExceptionFallback` | 変換不可で例外をスローする | 変換不可文字の検知・洗い出し |
| Best-Fit Fallback | （デフォルト動作の一部） | 似た文字にマッピングを試みる | OS/ランタイム依存 |

### 置換Fallback の使い方

```vb
' デフォルト：変換できない文字は「?」になる
Dim encDefault As Encoding = Encoding.GetEncoding(932)

' カスタム：変換できない文字を「■」にする
Dim encCustom As Encoding = Encoding.GetEncoding(
    932,
    New EncoderReplacementFallback("■"),   ' エンコード時（Unicode→CP932）
    DecoderFallback.ReplacementFallback     ' デコード時（CP932→Unicode）
)
```

- 第2引数: エンコード時（Unicode→CP932）のFallback ← **今回関係するのはこちら**
- 第3引数: デコード時（CP932→Unicode）のFallback

### 処理の流れ

```
Encoding.GetBytes("東京都○○区髙田１－２")

  東 → CP932にある → そのまま変換
  京 → CP932にある → そのまま変換
  ...
  髙 → CP932に無い → ★Fallback発動★
      → EncoderReplacementFallback("?")  なら「?」
      → EncoderReplacementFallback("■") なら「■」
      → EncoderExceptionFallback()       なら例外スロー
  田 → CP932にある → そのまま変換
  ...
```

1文字ずつ変換を試み、CP932にマッピングできない文字が出たときだけFallbackが発動する。
そのため、**CP932に無い文字をリスト管理する必要がない**のが最大のメリット。

### 例外Fallback による変換不可文字の洗い出し

`EncoderExceptionFallback` を使えば、変換不可文字の特定を自動化できる。

```vb
Dim encStrict As Encoding = Encoding.GetEncoding(
    932,
    New EncoderExceptionFallback(),
    DecoderFallback.ExceptionFallback
)

Try
    Dim bytes() As Byte = encStrict.GetBytes(value)
Catch ex As EncoderFallbackException
    ' ex.CharUnknown : 変換できなかった文字
    ' ex.Index       : その文字の位置
    Debug.WriteLine($"変換不可: '{ex.CharUnknown}' (U+{AscW(ex.CharUnknown):X4}) at index {ex.Index}")
End Try
```

本番では置換Fallback（「■」変換）を使いつつ、調査・ログ用途で例外Fallbackを併用することも可能。

---

## EncoderReplacementFallback 詳細解説

### 概要

.NETの文字コード変換において、マッピングできない文字が出現した際の処理を制御する仕組み。
`Encoding.GetEncoding` の第2引数（エンコード時）・第3引数（デコード時）で指定する。

### デフォルトの挙動

`Encoding.GetEncoding(932)` をそのまま使った場合、デフォルトのFallbackは `EncoderReplacementFallback("?")` である。
これが、現在発生している「?」文字化けの直接原因。

```
Unicode「髙」→ CP932に無い → Fallback発動 →「?」に置換
```

### Fallbackの種類

| 種類 | クラス名 | 挙動 | 用途 |
|---|---|---|---|
| 置換Fallback | `EncoderReplacementFallback` | 指定した文字列に置き換える | 今回の対応で使用 |
| 例外Fallback | `EncoderExceptionFallback` | 変換不可で例外をスローする | 変換不可文字の検知・洗い出し |
| Best-Fit Fallback | （デフォルト動作の一部） | 似た文字にマッピングを試みる | OS/ランタイム依存 |

### 置換Fallbackの使い方

```vb
' デフォルト：変換できない文字は「?」になる
Dim encDefault As Encoding = Encoding.GetEncoding(932)

' カスタム：変換できない文字を「■」にする
Dim encCustom As Encoding = Encoding.GetEncoding(
    932,
    New EncoderReplacementFallback("■"),   ' エンコード時（Unicode→CP932）
    DecoderFallback.ReplacementFallback     ' デコード時（CP932→Unicode）
)
```

- 第2引数：エンコード時（Unicode→CP932）のFallback ← 今回はここが重要
- 第3引数：デコード時（CP932→Unicode）のFallback

### 処理の流れ

```
Encoding.GetBytes("東京都○○区髙田１－２")

  東 → CP932にある → そのまま変換
  京 → CP932にある → そのまま変換
  ...
  髙 → CP932に無い → ★Fallback発動★
      → EncoderReplacementFallback("?")  なら「?」
      → EncoderReplacementFallback("■") なら「■」
      → EncoderExceptionFallback()       なら例外スロー
  田 → CP932にある → そのまま変換
  ...
```

1文字ずつ変換を試み、CP932にマッピングできない文字が出現した時のみFallbackが発動する。
そのため、CP932に存在しない文字を個別にリスト管理する必要がない。

### 例外Fallbackによる変換不可文字の洗い出し

`EncoderExceptionFallback` を使うと、変換不可文字の特定が可能。
調査・ログ用途で活用できる。

```vb
Dim encStrict As Encoding = Encoding.GetEncoding(
    932,
    New EncoderExceptionFallback(),
    DecoderFallback.ExceptionFallback
)

Try
    Dim bytes() As Byte = encStrict.GetBytes(value)
Catch ex As EncoderFallbackException
    ' ex.CharUnknown : 変換できなかった文字
    ' ex.Index       : その文字の位置
    Debug.WriteLine($"変換不可: '{ex.CharUnknown}' (U+{AscW(ex.CharUnknown):X4}) at index {ex.Index}")
End Try
```

本番環境では置換Fallback（「■」置換）を使用しつつ、調査時に例外Fallbackでログ出力して変換不可文字を洗い出すという併用も有効。

---

## 補足：半角混入問題とCP932変換不可問題は別問題

今回の送信側で発生している問題は、厳密には**2つの異なる問題**が混在している。

| # | 問題 | 例 | 原因 |
|---|---|---|---|
| ① | 半角文字の混入 | `A`, `1`, `ｱ` | データ入力ミス等 |
| ② | CP932に無い全角文字が「?」になる | 髙、麵、`U+2212` | Unicode→CP932変換時のマッピング不在 |

### Oracle SQLでの対応範囲

SQL側の `REGEXP_REPLACE` で半角文字を「■」に変換する方法は**①の半角混入には有効**である。

```sql
REGEXP_REPLACE(
    住所３,
    '[' || CHR(33) || '-' || CHR(126) ||
    UNISTR('\FF61') || '-' || UNISTR('\FF9F') || ']',
    '■'
)
```

しかし、**②のCP932変換不可文字には対応できない**。
髙（`U+9AD9`）や麵（`U+9EB5`）、MINUS SIGN（`U+2212`）等はUnicode上では「全角」に分類されるため、半角の範囲指定では検出されない。

SQLで②に対応しようとすると、CP932に存在しない文字をすべてリストアップして個別に `REPLACE` する必要があり、網羅性・保守性ともに現実的ではない。

### 対策の使い分け

| 問題 | 対策箇所 | 方法 |
|---|---|---|
| ①半角混入 | Oracle SQL or VB.NET | `REGEXP_REPLACE` or `ConvertHanToMark` |
| ②CP932変換不可文字 → 「?」 | **VB.NET一択** | `EncoderReplacementFallback("■")` による `ReplaceUnmappableChars` |

②は文字コードのエンコーディングレベルの問題であり、VB.NETの `EncoderReplacementFallback` を使うことでCP932に無い文字を自動的・網羅的に検出できる。SQLでの対応は困難。

---

## StreamWriterの改善提案

現行コードの `Encoding.Default` を明示的に指定することも推奨。

```vb
' 現行（暗黙的にShift_JIS）
New System.IO.StreamWriter(strFilePath, False, System.Text.Encoding.Default)

' 改善（明示的にCP932 + Fallback指定）
Dim enc As System.Text.Encoding = System.Text.Encoding.GetEncoding(
    932,
    New System.Text.EncoderReplacementFallback("■"),
    System.Text.DecoderFallback.ReplacementFallback
)
New System.IO.StreamWriter(strFilePath, False, enc)
```

これにより、仮に変換漏れがあっても「?」ではなく「■」になるため、受信側のエラーを防げる。

---

## 未決定事項

- [ ] 半角スペースの扱い（受信側の半角チェックと同様、保留中）
- [ ] 変換不可文字の洗い出し（近似変換マッピング表の拡充）
- [ ] ログ出力の要否（どの文字が変換されたかの記録）
- [ ] 対象カラムの範囲（住所３以外にも適用するか）
