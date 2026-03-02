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

### 案A: VB.NET側で変換不可文字を「■」に置換

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

### 案B: VB.NET側で近似文字に変換（個別マッピング）

変換不可文字を、意味的に近い文字に個別変換する。

#### 実装方法

```vb
''' <summary>
''' CP932に存在しない文字を近似文字に変換する
''' </summary>
Public Function ConvertToApproximate(value As String) As String
    If String.IsNullOrEmpty(value) Then Return value

    Dim sb As New System.Text.StringBuilder(value)

    ' 旧字体・異体字 → 常用漢字
    sb.Replace("髙", "高")
    sb.Replace("﨑", "崎")
    sb.Replace("濵", "浜")
    sb.Replace("麵", "麺")

    ' ハイフン系 → 全角ハイフンマイナス（CP932で変換可能）
    sb.Replace(ChrW(&H2212), "－")  ' MINUS SIGN
    sb.Replace(ChrW(&H2010), "－")  ' HYPHEN
    sb.Replace(ChrW(&H2013), "－")  ' EN DASH
    sb.Replace(ChrW(&H2014), "－")  ' EM DASH

    Return sb.ToString()
End Function
```

#### メリット・デメリット

| 観点 | 評価 |
|---|---|
| 実装コスト | △ マッピング表の作成・維持が必要 |
| 網羅性 | ✕ リストに無い文字は対応できない（漏れのリスク） |
| 保守性 | △ 新しい文字が出てきたら都度追加 |
| データ品質 | ◎ 元の意味を可能な限り保持 |

---

### 案C: 案Aと案Bの併用（推奨）

近似文字に変換できるものは変換し（案B）、それでも残った変換不可文字は「■」に置換する（案A）。

#### 実装方法

```vb
' 1. まず近似文字に変換
Dim address3 As String = dr("住所３").ToString()
address3 = ConvertToApproximate(address3)

' 2. それでも残った変換不可文字は「■」に
address3 = ReplaceUnmappableChars(address3)
```

#### メリット・デメリット

| 観点 | 評価 |
|---|---|
| 実装コスト | ○ 両方の関数が必要 |
| 網羅性 | ◎ 案Aがセーフティネットになる |
| 保守性 | ○ マッピング表は段階的に拡充可能 |
| データ品質 | ◎ 近似変換で救える文字は救い、残りは「■」 |

---

### 案D: Oracle SQL側で変換（参考）

SQL抽出時にOracle関数で変換する方法。

```sql
SELECT
    REGEXP_REPLACE(
        住所３,
        '[' ||
        CHR(33) || '-' || CHR(126) ||
        UNISTR('\FF61') || '-' || UNISTR('\FF9F') ||
        ']',
        '■'
    ) AS 住所３
FROM テーブル名
```

※ これは半角文字の変換用であり、CP932変換不可文字の対応とは別問題。
※ CP932変換不可文字の対応はVB.NET側（案A〜C）で行う方が適切。

---

## 対応案比較

| 観点 | 案A（■置換） | 案B（近似変換） | 案C（併用）★推奨 | 案D（SQL） |
|---|---|---|---|---|
| 実装コスト | ◎ | △ | ○ | △ |
| 網羅性 | ◎ | ✕ | ◎ | △ |
| 保守性 | ◎ | △ | ○ | △ |
| データ品質 | △ | ◎ | ◎ | △ |
| 受信側との共通化 | ○ | ✕ | ○ | ✕ |

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
